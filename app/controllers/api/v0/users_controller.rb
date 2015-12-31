module Api
  module V0
    class UsersController < Api::V0::BaseController
      skip_before_filter :authenticate_user!, except: [:update_me]

      def login
        user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: params[:phone], sms_code: params[:sms_code])
        return render 'unauthorized', status: :unauthorized unless user

        user.device_id = params['device_id'] if params['device_id'].present?
        user.device_type = params['device_type'] if params['device_type'].present?
        user.save

        render json: user, status: 200
      end

      def update_me
        if @current_user.update_attributes(user_params)
          render json: @current_user, status: 200
        else
          head 400
        end
      end

      def code
        if user_params[:phone].blank?
          return render json: {error: "Missing phone number"}, status:400
        end
        user = User.where(phone: user_params[:phone]).first!

        if params[:code][:action] == "regenerate"
          UserServices::SMSSender.new(user: user).send_welcome_sms!
          render json: user, status: 200
        else
          render json: {error: "Unknown action"}, status:400
        end
      end

      private
      def user_params
        params.require(:user).permit(:email, :sms_code, :phone)
      end
    end
  end
end
