module ChatServices
  class Deleter
    attr_reader :user, :chat_message, :callback

    def initialize user:, chat_message:
      @user = user
      @chat_message = chat_message

      @callback = DeleterCallback.new
    end

    def delete
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == chat_message.user_id

      if chat_message.update(status: :deleted, deleter: user, deleted_at: Time.zone.now)
        callback.on_success.try(:call, chat_message)
      else
        callback.on_failure.try(:call, chat_message)
      end
    end
  end

  class DeleterCallback < Callback
    attr_accessor :on_not_authorized

    def not_authorized(&block)
      @on_not_authorized = block
    end
  end
end
