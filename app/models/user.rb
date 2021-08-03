class User < ApplicationRecord
  include Onboarding::UserEventsTracking::UserConcern
  include UserServices::Engagement

  validates_presence_of [:phone, :sms_code, :token, :validation_status]
  validates_uniqueness_of :phone, scope: :community
  validates_uniqueness_of :token
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: -> (u) { u.email.to_s.size.zero? }
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }
  validates_presence_of [:first_name, :last_name, :email], if: Proc.new { |u| u.org_member? }
  validates :sms_code, length: { minimum: 6 }
  validates_length_of :about, maximum: 200, allow_nil: true
  validates_length_of :password, within: 8..256, allow_nil: true
  validates_inclusion_of :community, in: Community.slugs
  validates_inclusion_of :goal, in: -> (u) { (u.community&.goals || []).map(&:to_s) }, allow_nil: true
  validate :validate_roles!
  validate :validate_partner!
  validate :validate_interests!

  after_save :clean_up_passwords, if: :saved_change_to_encrypted_password?

  has_many :tours
  has_many :encounters, through: :tours
  has_many :login_histories
  has_many :session_histories
  has_many :entourages
  has_many :groups, -> { except_conversations }, class_name: :Entourage
  has_many :join_requests
  has_many :entourage_participations, through: :join_requests, source: :joinable, source_type: "Entourage"
  has_many :tour_participations, through: :join_requests, source: :joinable, source_type: "Tour"
  belongs_to :organization, optional: true
  has_and_belongs_to_many :coordinated_organizations, -> { distinct }, class_name: "Organization", join_table: "coordination", optional: true
  has_many :chat_messages
  has_many :conversation_messages
  has_many :user_applications
  has_many :user_relationships, foreign_key: "source_user_id", dependent: :destroy
  has_many :relations, through: :user_relationships, source: "target_user"
  has_many :invitations, class_name: "EntourageInvitation", foreign_key: "invitee_id"
  has_many :feeds
  belongs_to :partner, optional: true
  has_many :entourage_displays
  has_many :entourage_scores
  has_one :moderation, class_name: 'UserModeration'
  has_many :entourage_moderations, foreign_key: :moderator_id
  has_many :experimental_pending_request_reminders, class_name: 'Experimental::PendingRequestReminder'
  belongs_to :address, optional: true
  has_many :addresses, -> { order(:position) }, dependent: :destroy
  has_many :partner_join_requests
  has_many :user_phone_changes, -> { order(:id) }, dependent: :destroy
  has_many :histories, class_name: 'UserHistory'

  attr_reader :admin_password
  attr_reader :cnil_explanation

  validates_length_of :admin_password, within: 8..256, allow_nil: true
  validates :admin_password, confirmation: true, presence: false, if: Proc.new { |u| u.admin_password.present? }

  def departements
    addresses.where("country = 'FR' and postal_code <> ''").pluck("distinct left(postal_code, 2)")
  end

  def departement_slugs
    departements = addresses.pluck(:country, :postal_code).map do |country, postal_code|
      if country != 'FR' || postal_code.nil?
        departement = '*' # hors_zone
      else
        departement = postal_code.first(2)
      end
    end
    departements = ['_'] if departements.none? # sans_zone
    departements.uniq.map { |d| ModerationArea.departement_slug(d) }
  end

  enum device_type: [ :android, :ios ]
  attribute :roles, :jsonb_set
  attribute :interests, :jsonb_set

  scope :type_pro, -> { where(user_type: "pro") }
  scope :validated, -> { where(validation_status: "validated") }
  scope :blocked, -> { where(validation_status: "blocked") }
  scope :deleted, -> { where(deleted: true) }
  scope :anonymized, -> { where(validation_status: "anonymized") }
  scope :search_by, ->(search) {
    strip = search && search.strip
    like = "%#{strip}%"

    where(%(
      id = :id OR first_name ILIKE :first_name OR last_name ILIKE :last_name OR email ILIKE :email OR phone = :phone OR concat(first_name, ' ', last_name) ILIKE :full_name OR concat(last_name, ' ', first_name) ILIKE :full_name
    ), {
      id: strip.to_i,
      first_name: like,
      last_name: like,
      email: like,
      full_name: like,
      phone: Phone::PhoneBuilder.new(phone: strip).format,
    })
  }
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

  scope :left_joins_addresses, -> { joins('LEFT OUTER JOIN addresses ON addresses.user_id = users.id') }

  scope :in_area, -> (area) {
    if area.to_sym == :sans_zone
      left_joins_addresses.where("addresses.id IS NULL OR addresses.postal_code IS NULL")
    elsif area.to_sym == :hors_zone
      joins(:addresses).where("addresses.country != 'FR' OR left(addresses.postal_code, 2) NOT IN (?)", ModerationArea.only_departements)
    else
      joins(:addresses).where("addresses.country = 'FR' AND left(addresses.postal_code, 2) = ?", ModerationArea.departement(area))
    end
  }

  before_validation do
    self.goal = nil if goal.blank?

    if targeting_profile_changed? && !['partner', 'team'].include?(targeting_profile)
      self.partner_id = nil
    elsif partner_id_changed? && partner_id.present?
      self.targeting_profile = partner.staff ? 'team' : 'partner'
    end
  end

  def validate_phone!
    unless LegacyPhoneValidator.new(phone: self.phone).valid?
      errors.add(:phone, "devrait être au format +33... ou 06...")
    end
  end

  def validate_set_attr attribute
    return if community.nil?
    attribute = attribute.to_sym

    invalid = self[attribute] - community.send(attribute)
    invalid = yield invalid if block_given?

    errors.add(
      attribute,
      [
        invalid.map(&:inspect).to_sentence,
        (invalid.one? ? "n'est" : "ne sont"),
        "pas inclus dans la liste"
      ].join(' ')
    ) if invalid.any?
  end

  def validate_roles!
    validate_set_attr :roles do |invalid|
      invalid -= community.admin_roles if admin?
      invalid
    end
  end

  def validate_interests!
    validate_set_attr :interests
  end

  def validate_partner!
    if targeting_profile.in?(['partner', 'team'])
      if partner_id.blank?
        errors.add(:partner_id, :blank)
      else
        expected_targeting_profile = partner.staff ? 'team' : 'partner'
        errors.add(:targeting_profile) if targeting_profile != expected_targeting_profile
      end
    else
      errors.add(:partner_id, :present) unless partner_id.nil?
    end
  end

  def admin= is_admin
    if ['0', false].include?(is_admin)
      self.roles -= [:moderator]
    end

    super is_admin
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

  def admin_password=(new_password)
    @admin_password = new_password
    self.encrypted_admin_password = BCrypt::Password.create(new_password) if new_password.present?
  end

  def has_password?
    !encrypted_password.nil?
  end

  def generate_admin_password_token
   self.reset_admin_password_token = SecureRandom.hex(10)
   self.reset_admin_password_sent_at = Time.now.utc
   self
  end

  def admin_password_token_valid?
   (self.reset_admin_password_sent_at + 4.hours) > Time.now.utc
  end

  def reset_admin_password!
   self.reset_admin_password_token = nil
   save!
  end

  def pro?
    user_type=="pro"
  end

  def org_member?
    partner_id != nil
  end

  def moderator?
    roles.include?(:moderator)
  end

  def ambassador?
    targeting_profile == 'ambassador'
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

  def anonymized?
    validation_status=="anonymized"
  end

  def pending_phone_change_request
    return @pending_phone_change_request if @pending_phone_change_request.present?

    @pending_phone_change_request = user_phone_changes.last
    return nil unless @pending_phone_change_request && @pending_phone_change_request.kind == 'request'

    @pending_phone_change_request
  end

  def block! updater, cnil_explanation
    UserHistory.create({
      user_id: self.id,
      updater_id: updater.id,
      kind: 'block',
      metadata: {
        cnil_explanation: cnil_explanation
      }
    })
    update(validation_status: "blocked")
  end

  def unblock! updater, cnil_explanation
    UserHistory.create({
      user_id: self.id,
      updater_id: updater.id,
      kind: 'unblock',
      metadata: {
        cnil_explanation: cnil_explanation
      }
    })
    update(validation_status: "validated")
  end

  def validate!
    update(validation_status: "validated")
  end

  def anonymize!
    update_attributes(
      validation_status: "anonymized",
      email: "anonymized@#{Time.now.to_i}",
      phone: "+33100000000-#{Time.now.to_i}",
      first_name: "Cet utilisateur a été anonymisé",
      last_name: nil,
      deleted: true,
      address_id: nil
    )

    Address.where(user_id: id).delete_all
  end

  # TODO(partner)
  def default_partner
    nil # @default_partner ||= default_user_partners.first&.partner
  end

  # TODO(partner)
  def default_partner_id
    nil # user_partners.where(default: true).limit(1).pluck(:partner_id).first
  end

  # https://github.com/rails/rails/blob/v5.0.7.2/activerecord/lib/active_record/attributes.rb#L114
  attribute :community, :community

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

  def apple?
    id == 101 || address&.country == 'US'
  end

  def organization_name
    organization.name if organization_id
  end

  def organization_description
    organization.description if organization_id
  end

  def address_2
    addresses.find_by(position: 2)
  end

  protected

  def clean_up_passwords
    self.password = nil
  end
end
