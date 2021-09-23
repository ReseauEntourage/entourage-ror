require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ApplicationRecord
  validates_presence_of :area, :goal, :content, :title

  scope :with_status, -> (status) {
    if status.to_sym == :sending
      where(id: ConversationMessageBroadcast.pending_jobs.keys)
    else
      where(status: status)
    end
  }

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
    users.select('users.id').map(&:id)
  end

  def users
    return [] unless valid?

    targeting_profile = goal
    targeting_profile = 'asks_for_help' if goal.to_s == 'ask_for_help'
    targeting_profile = 'offers_help' if goal.to_s == 'offer_help'

    # targeting_profile prevails on goal
    # whenever broadcast goal is 'organization' then ambassador and partner' targeting_profiles are valids
    User
    .where('users.deleted': false, 'users.validation_status': :validated)
    .where([
      %(
        (users.targeting_profile = ? or
          (users.targeting_profile is null and users.goal = ?) or
          (users.targeting_profile in ('ambassador', 'partner') and 'organization' = ?)
        )
      ),
      targeting_profile,
      goal,
      goal
    ])
    .in_area(area)
    .group('users.id')
  end

  def clone
    ConversationMessageBroadcast.new(
      area: area,
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
end
