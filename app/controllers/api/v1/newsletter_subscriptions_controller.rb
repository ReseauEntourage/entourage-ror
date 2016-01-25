module Api
  module V1
    class NewsletterSubscriptionsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!

      def create
        newsletter_subscription = NewsletterSubscription.new(newsletter_subscription_params)
        if newsletter_subscription.save
          newsletter_subscription.send_mailchimp_info
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

