module SlackServices
  class ActionCloseMessage < Notifier
    def initialize action:, message:
      @action = action
      @message = message

      set_slack_notification(instance_type: @action.class.name, instance_id: @action.id)
    end

    def env
      ENV['SLACK_APP_WEBHOOKS']
    end

    def url
      "#{webhook 'prefix'}#{webhook(departement(@action.user)) || webhook('default')}"
    end

    def payload
      {
        text: 'Nouveau commentaire utilisateur',
        attachments: [
          {
            text: "<@#{slack_moderator_id(@action.user)}> ou team modération (département : #{departement(@action.user) || 'n/a'})"
          },
          {
            text: '%s vient de clôturer son action solidaire en laissant un commentaire' % @action.user.full_name
          },
          {
            text: "Commentaire : #{@message}"
          },
          {
            text: "Afficher l'action #{@action.title} : #{link_to_group(@action)}"
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
