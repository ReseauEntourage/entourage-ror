module Api
  module V0
    class UsersController < Api::V0::BaseController
      skip_before_filter :require_login, except: :update_me

      def login
        @user = User.includes(:organization).find_by_phone_and_sms_code params[:phone], params[:sms_code]
        #TODO : In case of incorrect credentials return a a 401, instead of a 400
        if @user.nil?
          render 'error', status: :bad_request
        else
          @user.device_id = params['device_id'] if params['device_id'].present?
          @user.device_type = params['device_type'] if params['device_type'].present?
          @user.save

          @tour_count = @user.tours.count
          @encounter_count = @user.encounters.count
        end
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
