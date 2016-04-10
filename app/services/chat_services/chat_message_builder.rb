module ChatServices
  class ChatMessageBuilder
    def initialize(params:, user:, joinable:, join_request:)
      @callback = ChatServices::Callback.new
      @user = user
      @joinable = joinable
      @message = joinable.chat_messages.new(params)
      @message.user = user
      @join_request = join_request
    end

    def create
      yield callback if block_given?

      return callback.on_freezed_tour.try(:call, message) if joinable.freezed?

      if message.save
        join_request.update(last_message_read: message.created_at)
        PushNotificationService.new.send_notification(user.full_name,
                                                      "Nouveau message",
                                                      message.content,
                                                      recipients,
                                                      {joinable_id: join_request.joinable_id,
                                                       joinable_type: join_request.joinable_type,
                                                       type: "NEW_CHAT_MESSAGE"})
        callback.on_create_success.try(:call, message)
      else
        callback.on_create_failure.try(:call, message)
      end
      joinable
    end

    private
    attr_reader :message, :user, :joinable, :join_request, :callback

    def recipients
      joinable.members.where("users.id != ? AND status = ?", user.id, "accepted")
    end
  end

  class Callback
    attr_accessor :on_create_success, :on_create_failure, :on_freezed_tour

    def create_success(&block)
      @on_create_success = block
    end

    def create_failure(&block)
      @on_create_failure = block
    end

    def freezed_tour(&block)
      @on_freezed_tour = block
    end
  end
end