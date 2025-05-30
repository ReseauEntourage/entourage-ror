require 'experimental/jsonb_set'

class ConversationMessageBroadcast < ApplicationRecord
  class << self
    def messageable_type
      raise NotImplementedError
    end

    def find_with_cast id
      record = find(id)

      return UserMessageBroadcast.find(id) if record.entourage_type?
      return NeighborhoodMessageBroadcast.find(id) if record.neighborhood_type?

      record
    end
  end

  def content_for_user user
    ChatMessage.interpolate(message: content, user: user)
  end

  def recipients
    raise NotImplementedError
  end

  def recipient_ids
    raise NotImplementedError
  end

  def entourage_type?
    conversation_type == 'Entourage'
  end

  def neighborhood_type?
    conversation_type == 'Neighborhood'
  end

  def read_count
    "n/a"
  end

  validates_presence_of :content, :title

  scope :with_status, -> (status) {
    if status.to_sym == :sending
      where(id: ConversationMessageBroadcast.pending_jobs.keys)
    else
      where(status: status)
    end
  }

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
    .where(messageable_type: self.class.messageable_type, message_type: :broadcast)
    .where('metadata @> ?', { conversation_message_broadcast_id: id }.to_json)
    .where('chat_messages.created_at >= ?', created_at)
  end

  def sent_count
    sent.count
  end

  def clone
    self.class.new(
      status: :draft,
      content: content,
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
