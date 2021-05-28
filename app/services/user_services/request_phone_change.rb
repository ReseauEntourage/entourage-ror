module UserServices
  class RequestPhoneChange
    CHANNEL = '#requested-phone-changes'
    USERNAME = 'Mobile-request'

    def initialize(user:)
      @user = user
    end

    def request(requested_phone)
      user_url = Rails.application.routes.url_helpers.admin_user_url(user.id, host: ENV['ADMIN_HOST'])

      Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']).ping(
        channel: CHANNEL,
        username: USERNAME,
        text: "L'utilisateur #{user.full_name} a requis un changement de numéro de téléphone",
        attachments: [{
          text: user_url,
        }, {
          text: "Téléphone requis : #{requested_phone}"
        }]
      )
    end

    private
    attr_reader :user
  end
end
