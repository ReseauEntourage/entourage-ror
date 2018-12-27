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

      if message.message_type == 'status_update'
        message.errors.add(:message_type, :inclusion)
        return callback.on_failure.try(:call, message)
      end

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
        join_request.update_column(:last_message_read, message.created_at)
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
  end

  class ChatMessageBuilderCallback < Callback
    attr_accessor :on_freezed_tour

    def freezed_tour(&block)
      @on_freezed_tour = block
    end
  end
end
