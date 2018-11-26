module UserServices
  module EmailPreferences
    def self.update_url(user:, accepts_emails:)
      Rails.application.routes.url_helpers.email_preferences_api_v1_user_url(
        user, accepts_emails: accepts_emails,
        signature: SignatureService.sign(user.id),
        host: API_HOST,
        protocol: :https
      )
    end
  end
end
