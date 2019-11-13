require 'experimental/jsonb_set'

class User < ActiveRecord::Base
  include Onboarding::UserEventsTracking

  validates_presence_of [:phone, :sms_code, :token, :validation_status]
  validates_uniqueness_of :phone, scope: :community
  validates_uniqueness_of :token
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: "email.to_s.size.zero?"
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }
  validates_presence_of [:first_name, :last_name, :email], if: Proc.new { |u| u.org_member? }
  validates :sms_code, length: { minimum: 6 }
  validates_length_of :about, maximum: 200, allow_nil: true
  validates_length_of :password, within: 8..256, allow_nil: true
  validates_inclusion_of :community, in: Community.slugs
  validate :validate_roles!
  validate :validate_partner!

  after_save :clean_up_passwords, if: :encrypted_password_changed?

  has_many :tours
  has_many :encounters, through: :tours
  has_many :login_histories
  has_many :session_histories
  has_many :entourages
  has_many :groups, -> { except_conversations }, class_name: :Entourage
  has_many :join_requests
  has_many :entourage_participations, through: :join_requests, source: :joinable, source_type: "Entourage"
  has_many :tour_participations, through: :join_requests, source: :joinable, source_type: "Tour"
  belongs_to :organization
  has_and_belongs_to_many :coordinated_organizations, -> { uniq }, class_name: "Organization", join_table: "coordination"
  has_many :chat_messages
  has_many :conversation_messages
  has_many :user_applications
  has_many :user_relationships, foreign_key: "source_user_id", dependent: :destroy
  has_many :relations, through: :user_relationships, source: "target_user"
  has_many :invitations, class_name: "EntourageInvitation", foreign_key: "invitee_id"
  has_many :feeds
  belongs_to :partner
  has_one :users_appetence
  has_many :entourage_displays
  has_many :entourage_scores
  has_many :user_newsfeeds
  has_one :moderation, class_name: 'UserModeration'
  has_many :entourage_moderations, foreign_key: :moderator_id
  has_many :experimental_pending_request_reminders, class_name: 'Experimental::PendingRequestReminder'
  belongs_to :address, dependent: :destroy

  enum device_type: [ :android, :ios ]
  attribute :roles, Experimental::JsonbSet.new

  scope :type_pro, -> { where(user_type: "pro") }
  scope :validated, -> { where(validation_status: "validated") }
  scope :blocked, -> { where(validation_status: "blocked") }
  scope :search_by, ->(first_name, last_name, email, phone) { where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ? OR phone = ?",
                                                                    first_name,
                                                                    last_name,
                                                                    email,
                                                                    phone) }
  scope :atd_friends, -> { where(atd_friend: true) }
  scope :accepts_email_category, -> (category_name) {
    email_category_id = EmailPreferencesService.category_id(category_name)
    joins(%{
      left join email_preferences
        on email_preferences.user_id = users.id
       and email_preferences.email_category_id = #{email_category_id}
       and email_preferences.subscribed = false
    })
    .where("email_preferences is null")
  }

  scope :with_event, -> (event_name, table_alias=nil) {
    table_alias ||= 'required_events_' + Digest::MD5.hexdigest(event_name).first(4)
    joins(%(
      join events #{table_alias}
        on #{table_alias}.user_id = users.id
       and #{table_alias}.name = '#{event_name}'
    ))
  }

  scope :without_event, -> (event_name, table_alias=nil) {
    table_alias ||= 'excluded_events_' + Digest::MD5.hexdigest(event_name).first(4)
    joins(%(
      left join events #{table_alias}
        on #{table_alias}.user_id = users.id
       and #{table_alias}.name = '#{event_name}'
    ))
    .where("#{table_alias} is null")
  }

  scope :moderators, -> { where(admin: true).where("roles ? 'moderator'") }

  before_validation do
    if targeting_profile == 'team'
      self.partner_id ||= Partner.where(name: 'Entourage').pluck(:id).first
    elsif targeting_profile_changed? && targeting_profile != 'partner'
      self.partner_id = nil
    elsif partner_id_changed? && partner_id.present?
      self.targeting_profile = 'partner'
    end
  end

  def validate_phone!
    unless LegacyPhoneValidator.new(phone: self.phone).valid?
      errors.add(:phone, "devrait être au format +33... ou 06...")
    end
  end

  def validate_roles!
    return if community.nil?

    invalid = roles - community.roles
    invalid -= community.admin_roles if admin?

    errors.add(
      :roles,
      [
        invalid.map(&:inspect).to_sentence,
        (invalid.one? ? "n'est" : "ne sont"),
        "pas inclus dans la liste"
      ].join(' ')
    ) if invalid.any?
  end

  def validate_partner!
    if targeting_profile == 'team'
      return
    end

    if targeting_profile == 'partner' && partner_id.blank?
      errors.add(:partner_id, :blank)
    end

    if targeting_profile != 'partner' && partner_id != nil
      errors.add(:partner_id, :present)
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
    self.encrypted_password = BCrypt::Password.create(new_password) if !new_password.nil?
  end

  def has_password?
    !encrypted_password.nil?
  end

  def pro?
    user_type=="pro"
  end

  def org_member?
    partner_id != nil
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

  # TODO(partner)
  def default_partner
    nil # @default_partner ||= default_user_partners.first&.partner
  end

  # TODO(partner)
  def default_partner_id
    nil # user_partners.where(default: true).limit(1).pluck(:partner_id).first
  end

  # https://github.com/rails/rails/blob/v4.2.10/activerecord/lib/active_record/attributes.rb
  attribute :community, Community::Type.new

  def joined_groups(status: :accepted, group_type: :except_conversations, exclude_created: false)
    scope = entourage_participations
    if group_type == :except_conversations
      scope = scope.except_conversations
    else
      scope = scope.where(group_type: group_type)
    end
    if exclude_created
      scope = scope.where.not(user_id: self.id)
    end
    scope = scope.merge(JoinRequest.where(status: status)) unless status == :all
    scope
  end

  def conversations(status: :accepted, group_type: :except_conversations)
    joined_groups(group_type: :conversation)
  end

  def anonymous?
    false
  end

  def organization_name
    organization.name if organization_id
  end

  def organization_description
    organization.description if organization_id
  end

  protected

  def clean_up_passwords
    self.password = nil
  end
end
