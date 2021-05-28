module UserServices
  class RequestPhoneChange
    USERNAME = 'Mobile-request'

    def initialize(user:)
      @user = user
    end

    def request(requested_phone:, email:)
      Slack::Notifier.new(webhook_url).ping(
        channel: channel,
        username: USERNAME,
        text: "L'utilisateur #{user.full_name}, #{email || '[Email non indiqué]'} a requis un changement de numéro de téléphone",
        attachments: [{
          text: user_url,
        }, {
          text: "Téléphone requis : #{requested_phone}"
        }]
      )
    end

    private
    attr_reader :user

    def host
      ENV['ADMIN_HOST']
    end

    def channel
      ENV['REQUEST_PHONE_CHANGE_CHANNEL']
    end

    def webhook_url
      ENV['SLACK_WEBHOOK_URL']
    end

    def user_url
      Rails.application.routes.url_helpers.admin_user_url(user.id, host: host)
    end
  end
end
