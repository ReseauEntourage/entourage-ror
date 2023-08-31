module Api
  module V1
    class ContactSubscriptionsController < Api::V1::BaseController
      skip_before_action :authenticate_user!

      #curl -X POST -d '{"contact_subscription": {"email": "foofoo@bar.com", "name": "foo", "profile": "foo", "subject": "foo", "message": "foo"}}' -H "Content-Type: application/json" "http://localhost:3000/api/v1/contact_subscriptions.json?token=azerty"
      def create
        pp contact_subscription_params
        contact_subscription = ContactSubscription.new(contact_subscription_params)

        if contact_subscription.save
          render json: contact_subscription, status: 201, serializer: ::V1::ContactSubscriptionSerializer
        else
          render json: { message: "Could not create contact subscription: #{contact_subscription.errors.full_messages}" }, status: 400
        end
      end

      private

      def contact_subscription_params
        params.require(:contact_subscription).permit(:email, :name, :profile, :subject, :message)
      end
    end
  end
end
