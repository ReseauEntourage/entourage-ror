module SlackServices
  class OffensiveText < Notifier
    def initialize chat_message_id:, text:
      @chat_message = ChatMessage.find(chat_message_id) if chat_message_id
      @text = text
    end

    def env
      ENV['SLACK_OFFENSIVE_WEBHOOK']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@chat_message.user)}> ou team modération (département : #{departement(@chat_message.user) || 'n/a'}) pouvez-vous vérifier ce texte ?",
        attachments: [
          {
            text: "Texte offensant : #{@text}"
          },
          {
            callback_id: [:offensive_text, @chat_message.id].join(':'),
            fallback: "",
            actions: [
              {
                text:  "Annuler le caractère offensant",
                type:  :button,
                style: :primary,
                name:  :action,
                value: :is_not_offensive
              },
              {
                text:  "Confirmer le contenu offensant",
                type:  :button,
                style: :danger,
                name:  :action,
                value: :is_offensive
              },
              {

                text: "Afficher",
                type: :button,
                url: link_to(@chat_message.messageable)
              }
            ]
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

    # used by Admin::SlackController.authenticate_slack_offensive_text! to authenticate webhook
    def self.webhook field
      SlackServices::OffensiveText.new(chat_message_id: nil, text: nil).webhook(field)
    end
  end
end
