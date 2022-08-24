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

      return callback.on_freezed_tour.try(:call, message) if joinable.is_a?(Tour) && joinable.freezed?

      if message.message_type == 'status_update'
        message.errors.add(:message_type, :inclusion)
        return callback.on_failure.try(:call, message)
      end

      success = false
      if joinable.new_record?
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

        join_request.update_column(:last_message_read, message.created_at) unless [Neighborhood, Outing].include?(joinable.class)

        AsyncService.new(self.class).send_notification(message)

        callback.on_success.try(:call, message)
      else
        callback.on_failure.try(:call, message)
      end

      joinable
    end

    private
    attr_reader :message, :user, :joinable, :join_request, :callback

    def self.send_notification(message)
      group = message.messageable

      group_title =
        if !group.respond_to?(:title) || group.group_type == 'conversation'
          nil
        else
          group.title
        end

      PushNotificationService.new.send_notification(
        UserPresenter.new(user: message.user).display_name,
        group_title,
        message.content,
        recipients(message),
        {
          joinable_id: group.id,
          joinable_type: group.class.name,
          group_type: group.group_type,
          type: "NEW_CHAT_MESSAGE"
        }
      )
    end

    def self.recipients(message)
      message.messageable.members.where("users.id != ? AND status = ?", message.user_id, "accepted")
    end

    def self.find_conversation recipient_id, user_id:
      participants = [recipient_id, user_id]
      uuid_v2 = ConversationService.hash_for_participants(participants)

      Entourage.where(group_type: :conversation).find_by(uuid_v2: uuid_v2) ||
        ConversationService.build_conversation(participant_ids: participants)
    end
  end

  class ChatMessageBuilderCallback < Callback
    attr_accessor :on_freezed_tour

    def freezed_tour(&block)
      @on_freezed_tour = block
    end
  end
end
