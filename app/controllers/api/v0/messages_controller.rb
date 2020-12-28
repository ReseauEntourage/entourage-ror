module Api
  module V0
    class MessagesController < Api::V0::BaseController
      skip_before_action :authenticate_user!

      def create
        message = Message.new(message_params)
        if message.save
          render json: message.as_json, status: 201
        else
          render json: {errors: message.errors.full_messages }, status: 400
        end
      end

      private

      def message_params
        params.require(:message).permit(:content, :first_name, :last_name, :email)
      end
    end
  end
end
