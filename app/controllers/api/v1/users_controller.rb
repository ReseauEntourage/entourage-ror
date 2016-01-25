module Api
  module V1
    class UsersController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:login, :code]

      def login
        user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: user_params[:phone], sms_code: user_params[:sms_code])
        return render json: {message: 'unauthorized'}, status: :unauthorized unless user

        render json: user, status: 200, serializer: ::V1::UserSerializer
      end

      def update
        if @current_user.update_attributes(user_params)
          render json: @current_user, status: 200, serializer: ::V1::UserSerializer
        else
          head 400
        end
      end

      def code
        if user_params[:phone].blank?
          return render json: {error: "Missing phone number"}, status:400
        end
        user_phone = Phone::PhoneBuilder.new(phone: user_params[:phone]).format
        user = User.where(phone: user_phone).first!

        if params[:code][:action] == "regenerate"
          UserServices::SMSSender.new(user: user).regenerate_sms!
          render json: user, status: 200, serializer: ::V1::UserSerializer
        else
          render json: {error: "Unknown action"}, status:400
        end
      end

      def show
        return render file: 'mocks/user.json'
      end

      private
      def user_params
        params.require(:user).permit(:email, :sms_code, :phone, :device_id, :device_type)
      end
    end
  end
end
