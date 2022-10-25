module SlackServices
  class SignalOuting < Notifier
    def initialize outing:, reporting_user:, signals:, message:
      @outing = outing
      @reporting_user = find_user(reporting_user)
      @signals = signals
      @message = message
    end

    def env
      ENV['SLACK_SIGNAL_OUTING_WEBHOOK']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@outing)}> ou team modération (département : #{departement(@outing) || 'n/a'}) pouvez-vous vérifier cet événement ?",
        attachments: [
          {
            text: "Événement : #{@outing.title} #{link_to_group(@outing)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Catégorie #{@signals}, message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end
  end
end
