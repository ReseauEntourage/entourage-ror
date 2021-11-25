module SlackServices
  class ActionCloseMessage < Notifier
    def initialize action:, message:
      @action = action
      @message = message
    end

    def env
      ENV['SLACK_APP_WEBHOOKS']
    end

    def url
      "#{webhook 'prefix'}#{webhook(departement(@action.user)) || webhook('default')}"
    end

    def payload
      {
        text: "<@#{slack_moderator_id(@action.user)}> ou team modération (département : #{departement(@action.user) || 'n/a'}) pouvez-vous vérifier cet utilisateur ?",
        attachments: [
          {
            text: "%s vient de clôturer son action solidaire en laissant un commentaire" % @action.user.full_name
          },
          {
            text: "Commentaire : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Nouveau commentaire d'un utilisateur",
      }
    end
  end
end
