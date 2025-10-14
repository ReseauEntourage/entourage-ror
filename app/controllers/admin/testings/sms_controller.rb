module Admin
  module Testings
    class SmsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :set_id
      before_action :authenticate_super_admin!

      def send_welcome
        TestingServices::Sms.new(current_user, :send_welcome).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Sms envoyé" } }
        end
      end

      def regenerate
        TestingServices::Sms.new(current_user, :regenerate).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Sms envoyé" } }
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
