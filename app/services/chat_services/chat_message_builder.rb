module ChatServices
  class ChatMessageBuilder
    def initialize(params:, user:, joinable:, join_request:)
      @callback = ChatServices::ChatMessageBuilderCallback.new
      @user = user
      @joinable = joinable
      @message = joinable.chat_messages.new(params)
      @message.user = user
      @join_request = join_request
    end

    def create
      yield callback if block_given?

      if message.message_type == 'status_update'
        message.errors.add(:message_type, :inclusion)
        return callback.on_failure.try(:call, message)
      end

      success = false
      if joinable.new_record? && joinable.is_a?(Entourage)
        # @caution this part assumes we built joinable using self.find_conversation
        success = begin
          ApplicationRecord.connection.transaction do
            joinable.create_from_join_requests!

            message.messageable = joinable
            message.save!
          end

          true
        rescue => e
          Raven.capture_exception(e)
          false
        end
      else
        success = message.save
      end

      if success
        message.check_spam!

        join_request.set_chat_messages_as_read_from(message.created_at) unless [Neighborhood, Outing, NeighborhoodMessageBroadcast].include?(joinable.class)

        callback.on_success.try(:call, message)
      else
        callback.on_failure.try(:call, message)
      end

      joinable
    end

    private
    attr_reader :message, :user, :joinable, :join_request, :callback

    def self.find_conversation recipient_id, user_id:
      participants = [recipient_id, user_id]
      uuid_v2 = ConversationService.hash_for_participants(participants)

      Entourage.where(group_type: :conversation).find_by(uuid_v2: uuid_v2) ||
        ConversationService.build_conversation(participant_ids: participants, creator_id: user_id)
    end
  end

  class ChatMessageBuilderCallback < Callback
  end
end
