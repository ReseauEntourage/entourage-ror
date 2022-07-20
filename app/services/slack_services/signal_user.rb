module SlackServices
  class SignalUser < Notifier
    def initialize reported_user:, reporting_user:, message:, signals:
      @reported_user = reported_user
      @reporting_user = find_user(reporting_user)
      @message = message
      @signals = signals
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@reported_user)}> ou team modération (département : #{departement(@reported_user) || 'n/a'}) pouvez-vous vérifier cet utilisateur ?",
        attachments: [
          {
            text: "Utilisateur signalé : #{@reported_user.full_name} #{link_to_user(@reported_user.id)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Message : #{@message}"
          },
          {
            text: "Catégories de signalement : #{@signals}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Signalement d’un utilisateur",
        channel: webhook('channel'),
      }
    end
  end
end
