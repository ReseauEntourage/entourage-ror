module SlackServices
  class SignalContribution < Notifier
    def initialize contribution:, reporting_user:, signals:, message:
      @contribution = contribution
      @reporting_user = find_user(reporting_user)
      @signals = signals
      @message = message

      set_slack_notification(instance_type: @contribution.class.name, instance_id: @contribution.id)
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@contribution)}> ou team modération (département : #{departement(@contribution) || 'n/a'}) pouvez-vous vérifier cette action de demande ?",
        attachments: [
          {
            text: "Événement : #{@contribution.title} #{link_to_group(@contribution)}"
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
