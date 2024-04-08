class UserMessageBroadcast < ConversationMessageBroadcast
  DEFAULT_FILTER_PERIOD = 1.year

  store_accessor :specific_filters, :has_engagement, :user_creation_date, :last_engagement_date, :interests

  class << self
    def messageable_type
      'Entourage'
    end

    def with_validated_profiles(users, goal)
      users.where('users.deleted': false, 'users.validation_status': :validated).with_profile(goal).group('users.id')
    end

    def in_area(users, area_type, generic_area, areas)
      return users.in_area(area_type) if generic_area

      users.in_specific_areas(areas)
    end

    def with_engagement(users, has_engagement)
      return users if has_engagement.nil?
      return users.where("users.id in (select user_id from denorm_daily_engagements)") if has_engagement

      users.where("users.id not in (select user_id from denorm_daily_engagements)")
    end

    def created_after(users, user_creation_date)
      return users unless user_creation_date

      users.where("users.created_at > ?", user_creation_date)
    end

    def engaged_after(users, last_engagement_date)
      return users unless last_engagement_date

      users.where("users.id in (select user_id from denorm_daily_engagements where date > ?)", last_engagement_date)
    end

    def with_interests(users, interests)
      return users unless interests.present?

      users.match_at_least_one_interest(interests)
    end
  end

  def recipients
    return UserMessageBroadcast.none unless valid?

    users = User.all
    users = self.class.with_validated_profiles(users, goal)
    users = self.class.in_area(users, area_type, generic_area?, areas)
    users = self.class.with_engagement(users, has_engagement)
    users = self.class.created_after(users, user_creation_date)
    users = self.class.engaged_after(users, last_engagement_date)
    # users = self.class.with_interests(users, interests)

    users
  end

  def recipient_ids
    recipients.pluck(:id)
  end

  alias_method :users, :recipients
  alias_method :user_ids, :recipient_ids

  AREA_TYPES = %w(national hors_zone sans_zone list).freeze
  AREA_FORMAT = /^([0-9]{2}|[0-9]{5})$/

  validates_presence_of :area_type, :goal
  validate :validate_areas_format

  default_scope { where(conversation_type: messageable_type) }

  # @param moderation_area Either (national, hors_zone, sans_zone) or "dep_xx"
  scope :with_moderation_area, -> (moderation_area) {
    return where(area_type: moderation_area) unless moderation_area.start_with? 'dep_'

    with_departement(ModerationArea.departement moderation_area)
  }

  scope :with_departement, -> (departement) {
    from('conversation_message_broadcasts, jsonb_array_elements_text(areas)')
      .where(area_type: 'list')
      .where('value like ?', "#{departement}%")
  }

  def validate_areas_format
    return unless area_type&.to_s == 'list'

    errors.add(:areas, 'ne doit pas être vide') if areas.compact.empty?
    errors.add(:areas, "doit contenir 2 chiffres (pour cibler un département) ou 5 chiffres (pour cibler une ville)") if areas.filter { |area| area !~ AREA_FORMAT }.any?
  end

  # @deprecated
  # @fixme
  # There is no moderation_area relationship
  def name
    if moderation_area
      "#{title} (#{area.departement}, #{goal})"
    else
      title
    end
  end

  def read_count
    sent.joins_group_join_requests
    .where('join_requests.last_message_read >= chat_messages.created_at')
    .where('join_requests.user_id != chat_messages.user_id')
    .count
  end

  def clone
    cloned = super
    cloned.assign_attributes(
      area_type: area_type,
      areas: areas,
      goal: goal
    )

    cloned
  end

  private

  def generic_area?
    ['national', 'hors_zone', 'sans_zone'].include? area_type
  end

  def specific_area?
    !generic_area?
  end

  public

  def has_engagement
    value = self["specific_filters"]["has_engagement"]

    return nil if value.nil?

    value == 'true'
  end

  def user_creation_date
    Date.parse(self["specific_filters"]["user_creation_date"]) unless self["specific_filters"]["user_creation_date"].nil?
  rescue ArgumentError
    nil
  end

  def last_engagement_date
    Date.parse(self["specific_filters"]["last_engagement_date"]) unless self["specific_filters"]["last_engagement_date"].nil?
  rescue ArgumentError
    nil
  end
end
