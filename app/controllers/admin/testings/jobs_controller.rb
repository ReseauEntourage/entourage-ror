module Admin
  module Testings
    class JobsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :set_id
      before_action :authenticate_super_admin!

      def push_notification_trigger_job
        TestingServices::Jobs.new(current_user, :push_notification_trigger_job).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Job créé" } }
        end
      end

      def notification_job
        TestingServices::Jobs.new(current_user, :notification_job).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Job de push notif créé" } }
        end
      end

      private

      def set_id
        @id = params[:id]
      end

      def handle_standard_error error
        respond_to do |format|
          format.js { render "admin/testings/error", locals: { message: "Erreur #{error.class.to_s}: #{error.message[0..1000]}" } }
        end
      end

      def handle_not_found error
        respond_to do |format|
          format.js { render "admin/testings/error", locals: { message: "Record not found" } }
        end
      end
    end
  end
end
