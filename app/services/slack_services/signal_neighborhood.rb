module SlackServices
  class SignalNeighborhood < Notifier
    def initialize neighborhood:, reporting_user:, signals:, message:
      @neighborhood = neighborhood
      @reporting_user = find_user(reporting_user)
      @signals = signals
      @message = message

      set_slack_notification(instance_type: @neighborhood.class.name, instance_id: @neighborhood.id)
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@neighborhood)}> ou team modération (département : #{departement(@neighborhood) || 'n/a'}) pouvez-vous vérifier ce groupe de voisinage ?",
        attachments: [
          {
            text: "Groupe de voisinage : #{@neighborhood.title} #{link_to_neighborhood(@neighborhood)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Catégories #{@signals.join(', ')}, message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Signalement d'un groupe de voisinage",
        channel: webhook('channel'),
      }
    end
  end
end
