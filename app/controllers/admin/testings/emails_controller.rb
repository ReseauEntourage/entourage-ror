module Admin
  module Testings
    class EmailsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :authenticate_super_admin!

      def weekly_planning
        TestingServices::Emails.new(current_user, :weekly_planning).run

        redirect_to admin_super_admin_testings_path, flash: { success: "Email envoyé" }
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
