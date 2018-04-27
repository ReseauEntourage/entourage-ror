class User < ActiveRecord::Base

  validates_presence_of [:phone, :sms_code, :token, :validation_status, :marketing_referer_id]
  validates_uniqueness_of [:token, :phone]
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: "email.to_s.size.zero?"
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }
  validates :sms_code, length: { minimum: 6 }
  validates_length_of :about, maximum: 200, allow_nil: true
  validates_presence_of [:password, :password_confirmation], if: :changing_password?
  validates_confirmation_of :password, if: :changing_password?
  validates_length_of :password, within: 8..256, allow_nil: true
  validates_inclusion_of :community, in: Community.slugs, allow_nil: true

  after_save :clean_up_passwords, if: :encrypted_password_changed?

  has_many :tours
  has_many :encounters, through: :tours
  has_many :login_histories
  has_many :entourages
  has_many :join_requests
  has_many :entourage_participations, through: :join_requests, source: :joinable, source_type: "Entourage"
  has_many :tour_participations, through: :join_requests, source: :joinable, source_type: "Tour"
  belongs_to :organization
  has_and_belongs_to_many :coordinated_organizations, -> { uniq }, class_name: "Organization", join_table: "coordination"
  has_many :chat_messages
  has_many :user_applications
  has_many :user_relationships, foreign_key: "source_user_id", dependent: :destroy
  has_many :relations, through: :user_relationships, source: "target_user"
  has_many :invitations, class_name: "EntourageInvitation", foreign_key: "invitee_id"
  has_many :authentication_providers, dependent: :destroy
  belongs_to :marketing_referer
  has_many :feeds
  has_many :user_partners, dependent: :destroy
  has_many :default_user_partners, -> { where(default: true) }, class_name: :UserPartner
  has_many :partners, through: :user_partners
  has_one :users_appetence
  has_many :entourage_displays
  has_many :entourage_scores
  has_many :user_newsfeeds
  has_one :moderation, class_name: 'UserModeration'
  has_many :action_zones
  has_many :experimental_pending_request_reminders, class_name: 'Experimental::PendingRequestReminder'

  enum device_type: [ :android, :ios ]

  delegate :name, :description, to: :organization, prefix: true

  scope :type_pro, -> { where(user_type: "pro") }
  scope :type_public, -> { where(user_type: "public") }
  scope :validated, -> { where(validation_status: "validated") }
  scope :blocked, -> { where(validation_status: "blocked") }
  scope :search_by, ->(first_name, last_name, email, phone) { where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone = ?",
                                                                    first_name,
                                                                    last_name,
                                                                    email,
                                                                    phone) }
  scope :atd_friends, -> { where(atd_friend: true) }

  def validate_phone!
    unless PhoneValidator.new(phone: self.phone).valid?
      errors.add(:phone, "devrait être au format +33... ou 06...")
    end
  end

  #Force all phone number to be inserted in DB in "+33" format
  def phone=(new_phone)
    super(Phone::PhoneBuilder.new(phone: new_phone).format)
  end

  def to_s
    "#{id} - #{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def sms_code=(another_sms_code)
    #Hashing slows down tests a lot
    if Rails.env.test? && ENV["DISABLE_CRYPT"]=="TRUE"
      return super(another_sms_code)
    end

    another_sms_code = BCrypt::Password.create(another_sms_code) unless (another_sms_code.nil?)
    super(another_sms_code)
  end

  attr_reader :password

  def password=(new_password)
    @password = new_password
    self.encrypted_password = BCrypt::Password.create(new_password) if new_password.present?
  end

  def has_password?
    !encrypted_password.nil?
  end

  def pro?
    user_type=="pro"
  end

  def public?
    user_type=="public"
  end

  def validated?
    validation_status=="validated"
  end

  def blocked?
    validation_status=="blocked"
  end

  def block!
    update(validation_status: "blocked")
  end

  def validate!
    update(validation_status: "validated")
  end
  alias_method :unblock!, :validate!

  def default_partner
    @default_partner ||= default_user_partners.first&.partner
  end

  def default_partner_id
    user_partners.where(default: true).limit(1).pluck(:partner_id).first
  end

  def community= community_or_slug
    super Community.slug(community_or_slug)
  end

  def community
    if Rails.env != 'production' && User.columns_hash['community'].null == false
      raise "This workaround must now be removed"
    end

    if super.present?
      Community.new(super)
    else
      $server_community
    end
  end

  protected

  def changing_password?
    !password.nil? || !password_confirmation.nil?
  end

  def clean_up_passwords
    self.password = self.password_confirmation = nil
  end
end
