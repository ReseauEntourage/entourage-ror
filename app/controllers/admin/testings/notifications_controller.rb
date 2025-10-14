module Admin
  module Testings
    class NotificationsController < Admin::BaseController
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

      before_action :set_id
      before_action :authenticate_super_admin!

      def user_smalltalk_on_almost_match
        TestingServices::Notifications.new(current_user, :user_smalltalk_on_almost_match).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
        end
      end

      def user_reaction_on_create
        TestingServices::Notifications.new(current_user, :user_reaction_on_create).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
        end
      end

      def ios_with_rpush
        TestingServices::Notifications.new(current_user, :ios_with_rpush).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
        end
      end

      def ios_without_rpush
        TestingServices::Notifications.new(current_user, :ios_without_rpush).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
        end
      end

      def android_with_rpush
        TestingServices::Notifications.new(current_user, :android_with_rpush).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
        end
      end

      def android_without_rpush
        TestingServices::Notifications.new(current_user, :android_without_rpush).run

        respond_to do |format|
          format.js { render "admin/testings/success", locals: { message: "Notification envoyée" } }
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
