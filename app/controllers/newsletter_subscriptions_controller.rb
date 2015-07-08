class NewsletterSubscriptionsController < ApplicationController

  skip_before_filter :require_login
  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  def create
    newsletter_subscription = NewsletterSubscription.new(newsletter_subscription_params)
    if newsletter_subscription.save
      render json: newsletter_subscription, status: :created
    else
      @entity = newsletter_subscription
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
