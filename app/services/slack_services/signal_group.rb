module SlackServices
  class SignalGroup < Notifier
    def initialize reported_group:, reporting_user:, message:
      @reported_group = reported_group
      @reporting_user = find_user(reporting_user)
      @message = message
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@reported_group)}> ou team modération (département : #{departement(@reported_group) || 'n/a'}) pouvez-vous vérifier cet utilisateur ?",
        attachments: [
          {
            text: "Action, événement signalé : #{@reported_group.title} #{link_to_group(@reported_group)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Signalement d'une action",
        channel: webhook('channel'),
      }
    end
  end
end
