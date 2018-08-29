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

      return callback.on_freezed_tour.try(:call, message) if joinable.freezed?


      success = false
      if joinable.new_record?
        success = begin
          ActiveRecord::Base.connection.transaction do
            join_requests = joinable.join_requests.to_a
            joinable.join_requests = []
            joinable.chat_messages = []
            joinable.instance_variable_set(:@readonly, false)
            joinable.save!
            join_requests.each do |join_request|
              join_request.joinable = joinable
              join_request.save!
            end
            message.messageable = joinable
            message.save!
          end
          true
        rescue
          false
        end
      else
        success = message.save
      end

      if success
        join_request.update(last_message_read: message.created_at)
        PushNotificationService.new.send_notification(UserPresenter.new(user: user).display_name,
                                                      "Nouveau message",
                                                      message.content,
                                                      recipients,
                                                      {joinable_id: join_request.joinable_id,
                                                       joinable_type: join_request.joinable_type,
                                                       group_type: joinable.group_type,
                                                       type: "NEW_CHAT_MESSAGE"})
        callback.on_success.try(:call, message)
      else
        callback.on_failure.try(:call, message)
      end
      joinable
    end

    private
    attr_reader :message, :user, :joinable, :join_request, :callback

    def recipients
      joinable.members.where("users.id != ? AND status = ?", user.id, "accepted")
    end
  end

  class ChatMessageBuilderCallback < Callback
    attr_accessor :on_freezed_tour

    def freezed_tour(&block)
      @on_freezed_tour = block
    end
  end
end
