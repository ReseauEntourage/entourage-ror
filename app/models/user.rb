class User < ActiveRecord::Base

  validates_presence_of [:phone, :sms_code, :token, :validation_status, :marketing_referer_id]
  validates_uniqueness_of [:token, :phone]
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: "email.to_s.size.zero?"
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }
  validates :sms_code, length: { minimum: 6 }
  validates_length_of :about, maximum: 200, allow_nil: true

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

  def default_partner
    @default_partner ||= default_user_partners.first&.partner
  end

  def default_partner_id
    user_partners.where(default: true).limit(1).pluck(:partner_id).first
  end
end
