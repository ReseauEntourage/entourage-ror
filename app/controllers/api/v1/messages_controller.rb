module Api
  module V1
    class MessagesController < Api::V1::BaseController
      skip_before_action :authenticate_user!

      #curl -H "Content-Type: application/json" -X POST -d '{"message": {"content": "foo bar", "first_name": "foo", "last_name": "bar", "email": "foo@bar.com"}}' "http://localhost:3000/api/v1/messages"
      def create
        message = Message.new(message_params)
        if message.save
          AdminMailer.received_message(message).deliver_later
          render json: message.as_json, status: 201
        else
          render_error(status: :unprocessable_entity, code: Api::V1::ErrorCodes::VALIDATION_ERROR, legacy: {errors: message.errors.full_messages})
        end
      end

      private

      def message_params
        params.require(:message).permit(:content, :first_name, :last_name, :email)
      end
    end
  end
end
