module ChatServices
  class Updater
    attr_reader :user, :chat_message, :params, :callback

    UPDATE_MESSAGE = "Votre message a été mis à jour car il ne respecte pas la charte de notre site. N'hésitez pas à me communiquer vos questions au besoin."

    def initialize user:, chat_message:, params:
      @user = user
      @chat_message = chat_message
      @params = params

      @callback = DeleterCallback.new
    end

    def update from_backoffice = false
      yield callback if block_given?

      return callback.on_not_authorized.try(:call) unless user.id == chat_message.user_id || (from_backoffice && user.admin?)

      chat_message.assign_attributes(params)

      return callback.on_failure.try(:call, chat_message) unless chat_message.save

      send_feedback_to_user if user.admin? && user.id != chat_message.user_id

      callback.on_success.try(:call, chat_message)
    end

    def send_feedback_to_user
      puts "-- send_feedback_to_user: #{user.id}, #{chat_message.user_id}"

      puts ConversationService.create_private_message!(sender_id: user.id, recipient_ids: [chat_message.user_id], content: UPDATE_MESSAGE)
    end
  end

  class DeleterCallback < Callback
    attr_accessor :on_not_authorized

    def not_authorized(&block)
      @on_not_authorized = block
    end
  end
end
