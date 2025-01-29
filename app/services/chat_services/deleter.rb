module ChatServices
  class Deleter
    attr_reader :user, :chat_message, :callback

    DELETE_MESSAGE = "Votre message a été supprimé car il ne respecte pas la charte de notre site. N'hésitez pas à me communiquer vos questions au besoin."

    def initialize user:, chat_message:
      @user = user
      @chat_message = chat_message

      @callback = DeleterCallback.new
    end

    def delete from_backoffice = false
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == chat_message.user_id || (from_backoffice && user.admin?)

      chat_message.assign_attributes(status: :deleted, deleter: user, deleted_at: Time.zone.now)

      return callback.on_failure.try(:call, chat_message) unless chat_message.save(validate: false)

      send_feedback_to_user if user.admin? && user.id != chat_message.user_id

      callback.on_success.try(:call, chat_message)
    end

    def send_feedback_to_user
      ConversationService.create_private_message!(sender_id: user.id, recipient_ids: [chat_message.user_id], content: DELETE_MESSAGE)
    end
  end

  class DeleterCallback < Callback
    attr_accessor :on_not_authorized

    def not_authorized(&block)
      @on_not_authorized = block
    end
  end
end
