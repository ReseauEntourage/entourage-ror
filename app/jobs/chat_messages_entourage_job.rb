require 'sidekiq/api'

# @todo RSPEC tests
class ChatMessagesEntourageJob
  include Sidekiq::Worker
  sidekiq_options :retry => false, queue: :default

  # @todo RSPEC tests
  # @caution we must perform as many jobs as the number of messages we have to create
  # performs the creation of a message from the sender in a specific entourage
  def perform(sender_id, entourage_id, content)
    user = User.find(sender_id)
    conversation = Entourage.find(entourage_id)
    join_request = JoinRequest.find_by!(joinable: conversation, user_id: sender_id)

    ChatServices::ChatMessageBuilder.new(
      user: user,
      joinable: conversation,
      join_request: join_request,
      params: {
        message_type: :text,
        content: content,
      }
    ).create
  end

  # ActiveJob interface
  def self.perform_later(sender_id, entourage_ids, content)
    entourage_ids.each do |entourage_id|
      perform_async(sender_id, entourage_id, content)
    end
  end
end
