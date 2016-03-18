module ChatServices
  class ChatMessageBuilder
    def initialize(params:, user:, tour:, tour_user:)
      @callback = ChatServices::Callback.new
      @user = user
      @tour = tour
      @message = tour.chat_messages.new(params)
      @message.user = user
      @tour_user = tour_user
    end

    def create
      yield callback if block_given?

      return callback.on_freezed_tour.try(:call, message) if tour.freezed?

      if message.save
        tour_user.update(last_message_read: message.created_at)
        PushNotificationService.new.send_notification(user.full_name,
                                                      "Nouveau message",
                                                      message.content,
                                                      recipients,
                                                      {tour_id: tour.id, type: "NEW_CHAT_MESSAGE"})
        callback.on_create_success.try(:call, message)
      else
        callback.on_create_failure.try(:call, message)
      end
      tour
    end

    private
    attr_reader :message, :user, :tour, :tour_user, :callback

    def recipients
      tour.members.where("users.id != ? AND status = ?", user.id, "accepted")
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