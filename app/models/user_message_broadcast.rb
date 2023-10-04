class UserMessageBroadcast < ConversationMessageBroadcast
  class << self
    def messageable_type
      'Entourage'
    end
  end

  def recipients
    return [] unless valid?

    users = User.where('users.deleted': false, 'users.validation_status': :validated)
      .with_profile(goal)
      .group('users.id')

    return users.in_area(area_type) if generic_area?

    users.in_specific_areas(areas)
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
end
