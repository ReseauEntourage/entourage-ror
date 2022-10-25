module SlackServices
  class SignalSolicitation < Notifier
    def initialize solicitation:, reporting_user:, signals:, message:
      @solicitation = solicitation
      @reporting_user = find_user(reporting_user)
      @signals = signals
      @message = message
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@solicitation)}> ou team modération (département : #{departement(@solicitation) || 'n/a'}) pouvez-vous vérifier cette action de demande ?",
        attachments: [
          {
            text: "Événement : #{@solicitation.title} #{link_to_group(@solicitation)}"
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
        username: "Signalement d'une action de demande",
        channel: webhook('channel'),
      }
    end
  end
end
