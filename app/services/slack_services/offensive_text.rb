module SlackServices
  class OffensiveText < Notifier
    def initialize instance:, text:
      @instance = instance
      @text = text
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@instance.user)}> ou team modération (département : #{departement(@instance.user) || 'n/a'}) pouvez-vous vérifier ce texte ?",
        attachments: [
          {
            text: "Texte offensant : #{@text}"
          }
        ]
      }
    end

    def payload_adds
      {
        username: "Texte offensant",
        channel: webhook('channel'),
      }
    end
  end
end
