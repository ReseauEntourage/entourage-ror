module UserServices
  class RequestPhoneChange
    USERNAME = 'Mobile-request'

    def initialize(user:)
      @user = user
    end

    def request(requested_phone:, email:)
      record_phone_request! requested_phone, email

      Slack::Notifier.new(webhook_url).ping(
        channel: channel,
        username: USERNAME,
        text: "L'utilisateur #{user.full_name}, #{email || '[Email non indiqué]'} a requis un changement de numéro de téléphone",
        attachments: [{
          text: user_url,
        }, {
          text: "Téléphone requis : #{requested_phone}"
        }, {
          text: "Département : #{user.addresses.pluck(:postal_code).join(', ')}"
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

    def record_phone_request! requested_phone, email
      UserPhoneChange.create(
        user_id: @user.id,
        kind: :request,
        phone_was: @user.phone,
        phone: requested_phone,
        email: email
      )
    end

    def self.record_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :change,
        phone_was: user.phone_was,
        phone: user.phone,
        email: user.email
      )
    end

    def self.cancel_phone_change! user:, admin:
      UserPhoneChange.create(
        user_id: user.id,
        admin_id: admin.id,
        kind: :cancel,
        phone_was: user.phone,
        phone: user.phone,
        email: user.email
      )
    end
  end
end
