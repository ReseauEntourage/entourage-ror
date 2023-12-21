module Api
  module V1
    class NewsletterSubscriptionsController < Api::V1::BaseController
      skip_before_action :authenticate_user!

      def show
        response = NewsletterServices::Contact.new(email: params[:email]).show do |on|
          on.success do |contact|
            render json: { contact: contact }, status: 200
          end

          on.failure do
            render json: { message: "Erreur lors de la recherche de #{newsletter_subscription_params[:email]}" }, status: 400
          end
        end
      end

      def create
        response = NewsletterServices::Contact.new(newsletter_subscription_params).create do |on|
          on.success do
            render json: { message: "Contact #{newsletter_subscription_params[:email]} ajouté" }, status: 201
          end

          on.failure do
            render json: { message: "Erreur lors de l'ajout de #{newsletter_subscription_params[:email]}" }, status: 400
          end
        end
      end

      def delete
        response = NewsletterServices::Contact.new(newsletter_subscription_params).delete do |on|
          on.success do
            render json: { message: "Contact #{newsletter_subscription_params[:email]} supprimé" }, status: 200
          end

          on.failure do
            render json: { message: "Erreur lors de la suppression de #{newsletter_subscription_params[:email]}" }, status: 400
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
