module Api
  module V0
    class NewsletterSubscriptionsController < Api::V0::BaseController
      skip_before_filter :authenticate_user!

      def create
        @newsletter_subscription = NewsletterSubscription.new(newsletter_subscription_params)
        if @newsletter_subscription.save
          @newsletter_subscription.send_mailchimp_info
          render status: 201
        else
          @entity = @newsletter_subscription
          render "application/400", status: 400
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

