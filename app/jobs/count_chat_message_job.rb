class CountChatMessageJob
  include Sidekiq::Worker

  sidekiq_options retry: true, queue: :default

  def perform messageable_type, messageable_id
    return unless klass = messageable_type.constantize
    return unless instance = klass.find(messageable_id)
    return unless instance.respond_to?(:number_of_root_chat_messages)

    instance.update_attribute(:number_of_root_chat_messages,
      number_of_root_chat_messages(messageable_type, messageable_id)
    )
  end

  def number_of_root_chat_messages messageable_type, messageable_id
    ChatMessage
      .where(messageable_type: messageable_type, messageable_id: messageable_id, ancestry: nil)
      .where.not(status: :deleted)
      .count
  end

  def self.perform_later messageable_type, messageable_id
    CountChatMessageJob.perform_async(messageable_type, messageable_id)
  end
end
