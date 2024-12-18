module SlackServices
  class OffensiveText < Notifier
    def initialize instance:, text:
      @instance = instance
      @text = text
    end

    def env
      ENV['SLACK_OFFENSIVE_WEBHOOK']
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@instance.user)}> ou team modération (département : #{departement(@instance.user) || 'n/a'}) pouvez-vous vérifier ce texte ?",
        attachments: [
          {
            text: "Texte offensant : #{@text}"
          },
          {
            callback_id: [:offensive_text, @instance.id].join(':'),
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
                url: link_to(@instance.messageable)
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
      SlackServices::UnblockUser.new(user_id: nil).webhook(field)
    end
  end
end
