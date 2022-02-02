require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ApplicationRecord
  AREA_TYPES = %w(national hors_zone sans_zone list).freeze

  validates_presence_of :area_type, :goal, :content, :title

  scope :with_status, -> (status) {
    if status.to_sym == :sending
      where(id: ConversationMessageBroadcast.pending_jobs.keys)
    else
      where(status: status)
    end
  }

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

  def status= status
    if status == :archived
      self['archived_at'] = Time.now
    elsif status == :sent
      self['sent_at'] = Time.now
    end
    super(status)
  end

  def archived?
    !!archived_at
  end

  def draft?
    status&.to_sym == :draft
  end

  def sending?
    self.class.pending_jobs.keys.include? id
  end

  def sent?
    status&.to_sym == :sent
  end

  def sent
    ChatMessage
    .where(messageable_type: 'Entourage', message_type: :broadcast)
    .where('metadata @> ?', { conversation_message_broadcast_id: id }.to_json)
  end

  def sent_count
    sent.count
  end

  def read_count
    sent.joins_group_join_requests
    .where('join_requests.last_message_read >= chat_messages.created_at')
    .where('join_requests.user_id != chat_messages.user_id')
    .count
  end

  def user_ids
    users.pluck(:id)
  end

  def users
    return [] unless valid?

    users = User.where('users.deleted': false, 'users.validation_status': :validated)
      .with_profile(goal)
      .group('users.id')

    return users.in_area(area_type) if generic_area?

    users.in_specific_areas(areas)
  end

  def clone
    ConversationMessageBroadcast.new(
      area: area, # @deprecated
      area_type: area_type,
      areas: areas,
      content: content,
      goal: goal,
      title: title
    )
  end

  def self.pending_jobs
    ConversationMessageBroadcastJob.count_jobs_by_tags
  end

  def delete_jobs
    ConversationMessageBroadcastJob.delete_jobs_with_tag id
  end

  private

  def generic_area?
    ['national', 'hors_zone', 'sans_zone'].include? area_type
  end

  def specific_area?
    !generic_area?
  end
end
