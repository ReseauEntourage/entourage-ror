module SlackServices
  class SignalNeighborhood < Notifier
    def initialize neighborhood:, reporting_user:, message:
      @neighborhood = neighborhood
      @reporting_user = find_user(reporting_user)
      @message = message
    end

    def env
      ENV['SLACK_SIGNAL_NEIGHBORHOOD_WEBHOOK']
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
            text: "Message : #{@message}"
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
