module Admin
  module Testings
    class JobsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :authenticate_super_admin!

      def push_notification_trigger_job
        TestingServices::Jobs.new(current_user, :push_notification_trigger_job).run

        redirect_to admin_super_admin_testings_path, flash: { success: "Job créé" }
      end

      def notification_job
        TestingServices::Jobs.new(current_user, :notification_job).run

        redirect_to admin_super_admin_testings_path, flash: { success: "Job de push notif créée" }
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
