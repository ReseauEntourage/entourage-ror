module Admin
  class NewsletterSubscriptionsController < Admin::BaseController
    def index
      @newsletter_subscriptions = NewsletterSubscription.page(params[:page])
    end
  end
end
