module Api
  module V1
    class NotificationsController < Api::V1::BaseController
      def welcome
        Onboarding::Timeliner.new(current_user.id, :h1_after_registration).run
      end

      def at_day
        Onboarding::Timeliner.new(current_user.id, "j#{params[:day]}_after_registration").run
      end
    end
  end
end
