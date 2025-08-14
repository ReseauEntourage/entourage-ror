module Admin
  module Testings
    class NotificationsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :authenticate_super_admin!

      def user_smalltalk_on_almost_match
        TestingServices::Notifications.new(current_user, :user_smalltalk_on_almost_match).run

        redirect_to admin_super_admin_testings_path, flash: { success: "Notification envoyée" }
      end

      def user_reaction_on_create
        TestingServices::Notifications.new(current_user, :user_reaction_on_create).run

        redirect_to admin_super_admin_testings_path, flash: { success: "Notification envoyée" }
      end

      private

      def handle_standard_error error
        redirect_to admin_super_admin_testings_path, flash: { error: "Erreur #{error.class.to_s}: #{error.message[0..1000]}" }
      end

      def handle_not_found error
        redirect_to admin_super_admin_testings_path, flash: { error: "Record not found" }
      end
    end
  end
end
