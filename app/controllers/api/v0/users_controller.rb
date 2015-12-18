module Api
  module V0
    class UsersController < Api::V0::BaseController
      skip_before_filter :authenticate_user!, except: :update_me

      def login
        @user = UserServices::UserAuthenticator.authenticate_by_phone_and_sms(phone: params[:phone], sms_code: params[:sms_code])
        return render 'unauthorized', status: :unauthorized unless @user

        @user.device_id = params['device_id'] if params['device_id'].present?
        @user.device_type = params['device_type'] if params['device_type'].present?
        @user.save
        
        @tour_count = @user.tours.count
        @encounter_count = @user.encounters.count
      end

      def update_me
        if @current_user.update_attributes(self_user_params)
          @user = @current_user
          render 'show'
        else
          head 400
        end
      end

      private

      def self_user_params
        params.require(:user).permit(:email, :sms_code)
      end
    end
  end
end
