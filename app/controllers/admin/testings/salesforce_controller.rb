module Admin
  module Testings
    class SalesforceController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :set_id
      before_action :authenticate_super_admin!

      def outing_sync
        service = TestingServices::Salesforce.new(current_user, :outing_sync)
        service.run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Synchronisation envoyée: #{service.outing.name} (#{service.outing.id})" } }
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
