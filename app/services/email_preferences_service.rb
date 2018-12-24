module EmailPreferencesService
  def self.update_url(user:, accepts_emails:)
    Rails.application.routes.url_helpers.email_preferences_api_v1_user_url(
      user, accepts_emails: accepts_emails,
      signature: SignatureService.sign(user.id),
      host: API_HOST,
      protocol: :https
    )
  end

  def self.enable_callback?
    !Rails.env.test?
  end

  def self.sync_mailchimp_subscription_status user
    if user.accepts_emails
      MailchimpService.update(
        :newsletter, user.email,
        status: :subscribed
      ) rescue MailchimpService::ResourceNotFound
    else
      MailchimpService.add_or_update(
        :newsletter, user.email,
        status: :unsubscribed,
        status_if_new: :unsubscribed,
        unsubscribe_reason: "via le site"
      ) rescue MailchimpService::ForgottenEmailNotSubscribed
    end
  rescue MailchimpService::ConfigError => e
    Raven.capture_exception(e)
  end

  module Callback
    extend ActiveSupport::Concern

    included do
      after_commit :sync_mailchimp_subscription_status_async
    end

    private

    def sync_mailchimp_subscription_status_async
      return unless EmailPreferencesService.enable_callback?
      return unless previous_changes.keys.include?('accepts_emails')
      AsyncService.new(EmailPreferencesService)
        .sync_mailchimp_subscription_status(self)
    end
  end
end
