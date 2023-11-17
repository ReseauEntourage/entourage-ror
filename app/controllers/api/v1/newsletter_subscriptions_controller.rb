module Api
  module V1
    class NewsletterSubscriptionsController < Api::V1::BaseController
      skip_before_action :authenticate_user!

      def create
        response = NewsletterServices::Contact.create(newsletter_subscription_params) do |on|
          on.success do |newsletter_subscription|
            render json: { message: "contact #{params[:email]} ajouté" }
          end

          on.failure do |newsletter_subscription|
            render json: { message: "Erreur lors de l'ajout de #{params[:email]}", status: 400 }
          end
        end
      end

      private

      def newsletter_subscription_params
        params.require(:newsletter_subscription).permit(:email, :zone, :status, :active)
      end
    end
  end
end
