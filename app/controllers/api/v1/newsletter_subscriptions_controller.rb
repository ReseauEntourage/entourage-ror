module Api
  module V1
    class NewsletterSubscriptionsController < Api::V1::BaseController
      skip_before_action :authenticate_user!

      #curl -X POST -d '{"newsletter_subscription": {"email": "foofoo@bar.com", "active": true}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/newsletter_subscriptions.json?token=azerty"
      def create
        newsletter_subscription = NewsletterSubscription.new(newsletter_subscription_params)
        if newsletter_subscription.save
          SubscribeNewsletterMailchimpJob.perform_later(newsletter_subscription.email, newsletter_subscription.active)
          render json: newsletter_subscription, status: 201, serializer: ::V1::NewsletterSubscriptionSerializer
        else
          @entity = @newsletter_subscription
          render json: {message: "Could not create newsletter subscription"}, status: 400
        end
      end

      private

      def newsletter_subscription_params
        if params[:newsletter_subscription]
          params.require(:newsletter_subscription).permit(:email, :active)
        end
      end
    end
  end
end
