module SlackServices
  class RequestPhoneChange < Notifier
    USERNAME = 'Changement de téléphone'

    def initialize user:, requested_phone:
      @user = user
      @requested_phone = requested_phone

      set_slack_notification(instance_type: @user.class.name, instance_id: @user.id, options: {
        requested_phone: @requested_phone,
      })
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}) L'utilisateur #{@user.full_name} a requis un changement de numéro de téléphone",
        attachments: [{
          text: link_to_user(@user.id),
        }, {
          text: "Téléphone requis : #{@requested_phone}"
        }, {
          text: "Département : #{@user.addresses.pluck(:postal_code).join(', ')}"
        }]
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end

    def webhook field
      return ENV['SLACK_WEBHOOK_URL'] if field == 'url'
      return ENV['REQUEST_PHONE_CHANGE_CHANNEL'] if field == 'channel'
      return USERNAME if field == 'username'

      nil
    end
  end
end
