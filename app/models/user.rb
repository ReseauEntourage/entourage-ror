class User < ApplicationRecord
  include Interestable
  include Onboarding::UserEventsTracking::UserConcern
  include UserServices::Engagement

  TEMPORARY_BLOCK_PERIOD = 1.month
  PROFILES = [:offer_help, :ask_for_help, :organization, :goal_not_known]
  STATUSES = [:validated, :blocked, :temporary_blocked, :deleted, :pending]
  ROLES = [:moderator, :admin]

  validates_presence_of [:phone, :sms_code, :token, :validation_status]
  validates_uniqueness_of :phone, scope: :community
  validates_uniqueness_of :token
  validate :validate_phone!
  validates_format_of :email, with: /@/, unless: -> (u) { u.email.to_s.size.zero? }
  validates_presence_of [:first_name, :last_name, :organization, :email], if: Proc.new { |u| u.pro? }
  validates_associated :organization, if: Proc.new { |u| u.pro? }
  validates_presence_of [:first_name, :last_name, :email], if: Proc.new { |u| u.org_member? }
  validates :sms_code, length: { minimum: 6 }
  validates :sms_code_password, length: { minimum: 6 }, if: Proc.new { |u| u.sms_code_password.present? }
  validates_length_of :about, maximum: 200, allow_nil: true
  validates_length_of :password, within: 8..256, allow_nil: true
  validates_inclusion_of :community, in: Community.slugs
  validates_inclusion_of :goal, in: -> (u) { (u.community&.goals || []).map(&:to_s) }, allow_nil: true
  validate :validate_roles!
  validate :validate_partner!
  validate :validate_interests!
  validate :validate_birthday!

  after_save :clean_up_passwords, if: :saved_change_to_encrypted_password?

  has_many :tours
  has_many :encounters, through: :tours
  has_many :followings, -> { where active: true }
  has_many :subscriptions, through: :followings, source: :partner
  has_many :login_histories
  has_many :session_histories
  has_many :user_histories
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

  delegate :country, to: :address, allow_nil: true
  delegate :postal_code, to: :address, allow_nil: true
  delegate :latitude, to: :address, allow_nil: true
  delegate :longitude, to: :address, allow_nil: true

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

  def postal_codes
    addresses.pluck(:postal_code)
  end

  enum device_type: [ :android, :ios ]
  attribute :roles, :jsonb_set

  scope :type_pro, -> { where(user_type: "pro") }
  scope :validated, -> { where(validation_status: "validated") }
  scope :deleted, -> { where(deleted: true) }
  scope :anonymized, -> { where(validation_status: "anonymized") }
  scope :blocked, -> { where(validation_status: "blocked") }
  scope :temporary_blocked, -> { blocked.where('unblock_at is not null') }
  scope :status_is, -> (status) {
    return unless status.present?

    status = status.to_sym

    return if status == :all
    return deleted if status == :deleted
    return blocked.where('unblock_at is not null') if status == :temporary_blocked
    return where(id: UserPhoneChange.pending_user_ids) if status == :pending

    where(validation_status: status)
  }
  scope :role_is, -> (role) {
    return unless role.present?

    role = role.to_sym

    return moderators if role == :moderator
    return where(admin: true) if role == :admin
  }
  scope :goal_not_known, -> { where(targeting_profile: nil, goal: nil) }
  scope :unknown, -> { goal_not_known }
  scope :ask_for_help, -> { where('(targeting_profile is null and goal = ?) or targeting_profile = ?', :ask_for_help, :asks_for_help) }
  scope :offer_help, -> { where('(targeting_profile is null and goal = ?) or targeting_profile = ?', :offer_help, :offers_help) }
  scope :organization, -> { where(goal: :organization) }
  scope :search_by, ->(search) {
    strip = search && search.strip
    like = "%#{strip}%"

    where(%(
      users.id = :id OR
      trim(first_name) ILIKE :first_name OR
      trim(last_name) ILIKE :last_name OR
      email ILIKE :email OR
      phone = :phone OR
      concat(trim(first_name), ' ', trim(last_name)) ILIKE :full_name OR
      concat(trim(last_name), ' ', trim(first_name)) ILIKE :full_name
    ), {
      id: strip.to_i,
      first_name: like,
      last_name: like,
      email: like,
      full_name: like,
      phone: Phone::PhoneBuilder.new(phone: strip).format,
    })
  }
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

  scope :with_profile, -> (profile) {
    if profile.to_sym == :ask_for_help
      ask_for_help
    elsif profile.to_sym == :offer_help
      offer_help
    elsif profile.to_sym == :organization
      organization
    elsif profile.to_sym == :goal_not_known
      goal_not_known
    end
  }

  scope :in_area, -> (area) {
    if area.to_sym == :sans_zone
      left_joins_addresses.where("addresses.id IS NULL OR addresses.postal_code IS NULL")
    elsif area.to_sym == :hors_zone
      joins(:addresses).where("addresses.country != 'FR' OR left(addresses.postal_code, 2) NOT IN (?)", ModerationArea.only_departements)
    elsif area.to_sym == :national
      joins(:addresses).where("addresses.country = 'FR'")
    else
      joins(:addresses).where("addresses.country = 'FR' AND left(addresses.postal_code, 2) = ?", ModerationArea.departement(area))
    end
  }

  # from departements or postal_codes
  scope :in_specific_areas, -> (areas) {
    joins(:addresses).where("addresses.country = 'FR' and postal_code SIMILAR TO ?", "(#{areas.join('|')})%")
  }

  scope :in_conversation_with, -> (user_id) {
    select("users.*")
    .joins(join_requests: { entourage: :chat_messages })
    .where(%(
      users.id != :user_id
      and chat_messages.user_id = :chat_message_user_id
      and entourages.group_type = 'conversation'
    ), {
      user_id: user_id,
      chat_message_user_id: user_id
    })
    .group('users.id')
  }

  before_validation do
    self.goal = nil if goal.blank?

    if targeting_profile_changed? && !['partner', 'team'].include?(targeting_profile)
      self.partner_id = nil
    elsif partner_id_changed? && partner_id.present?
      self.targeting_profile = partner.staff ? 'team' : 'partner'
    end
  end

  def status
    return 'deleted' if deleted?

    validation_status
  end

  def validate_phone!
    unless LegacyPhoneValidator.new(phone: self.phone).valid?
      errors.add(:phone, "devrait être au format +33... ou 06...")
    end
  end

  def validate_set_attr attribute
    return if community.nil?
    attribute = attribute.to_sym

    invalid = send(attribute) - community.send(attribute)
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

  def validate_birthday!
    return unless birthday.present?

    Date.strptime("#{birthday}-2024", '%d-%m-%y')
  rescue
    errors.add(:birthday, "Date invalide")
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
    unless ActiveModel::Type::Boolean.new.cast(is_admin)
      self.roles -= [:moderator]
    end

    super is_admin
  end

  def moderator= is_moderator
    if ActiveModel::Type::Boolean.new.cast(is_moderator)
      self.roles += [:moderator]
    else
      self.roles -= [:moderator]
    end

    self.roles.uniq
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

  attr_accessor :sms_code_password
  attr_reader :password

  def sms_code_password=(new_sms_code_password)
    return unless new_sms_code_password.present?

    @sms_code_password = new_sms_code_password

    self.sms_code = new_sms_code_password
  end

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

  # @duplicated method
  def moderator
    roles.include?(:moderator)
  end

  def ambassador?
    targeting_profile == 'ambassador'
  end

  def is_ask_for_help?
    (targeting_profile.blank? && goal.to_s == 'ask_for_help') || targeting_profile.to_s == 'asks_for_help'
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

  def temporary_blocked?
    blocked? && unblock_at && unblock_at > Time.now
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
        cnil_explanation: cnil_explanation,
        temporary: false
      }
    })
    update(validation_status: "blocked")
  end

  def temporary_block! updater, cnil_explanation
    UserHistory.create({
      user_id: self.id,
      updater_id: updater.id,
      kind: 'block',
      metadata: {
        cnil_explanation: cnil_explanation,
        temporary: true
      }
    })
    update(validation_status: "blocked", unblock_at: Time.now + TEMPORARY_BLOCK_PERIOD)
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
    update(validation_status: "validated", unblock_at: nil)
  end

  def validate!
    update(validation_status: "validated")
  end

  def anonymize! updater
    UserHistory.create({
      user_id: self.id,
      updater_id: updater.id,
      kind: 'anonymize',
      metadata: {}
    })

    update_attributes(
      validation_status: "anonymized",
      email: "anonymized@#{Time.now.to_i}",
      phone: "+33100000000-#{Time.now.to_i}",
      first_name: "Cet utilisateur a supprimé son compte",
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

  def active_invitations
    EntourageInvitation.where(invitee_id: id).joins(:invitable).where(%(
      entourages.status = 'open' AND (
        group_type != 'outing'
        OR entourages.metadata->>'ends_at' IS NULL OR entourages.metadata->>'ends_at' > ?
      )
    ), Time.now)
  end

  def action_creations_count
    entourages.where(group_type: :action).count
  end

  def action_participations_count
    entourage_participations.where(group_type: :action).count
  end

  def outing_participations_count
    entourage_participations.where(group_type: :outing).count
  end

  def conversation_participations_count
    entourage_participations.where(group_type: :conversation).count
  end


  protected

  def clean_up_passwords
    self.password = nil
  end
end
