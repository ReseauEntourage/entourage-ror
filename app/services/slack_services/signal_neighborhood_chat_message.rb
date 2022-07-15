module SlackServices
  class SignalNeighborhoodChatMessage < Notifier
    def initialize chat_message:, reporting_user:, signals:, message:
      @reporting_user = find_user(reporting_user)

      @chat_message = chat_message
      @neighborhood = chat_message.messageable
      @signals = signals
      @message = message
      @content = chat_message.content
    end

    def env
      ENV['SLACK_SIGNAL_NEIGHBORHOOD_WEBHOOK']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@neighborhood)}> ou team modération (département : #{departement(@neighborhood) || 'n/a'}) pouvez-vous vérifier le message de ce groupe de voisinage ?",
        attachments: [
          {
            text: "Groupe de voisinage : #{@neighborhood.title} #{link_to_neighborhood(@neighborhood)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user.id)}"
          },
          {
            text: "Message signalé : #{@content}"
          },
          {
            text: "Catégories #{@signals.join(', ')}, message : #{@message}"
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
