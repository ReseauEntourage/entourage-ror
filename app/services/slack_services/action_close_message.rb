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
        text: nil,
        attachments: [
          {
            color: "#36a64f",
            blocks: [
              {
                type: "section",
                fields: [
                  {
                    type: "mrkdwn",
                    text: "*Nom :*\n#{@action.user.full_name}"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Accéder au profil :*\n<#{link_to_user(@action.user_id)}|Cliquez ici>"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Contact :*\n<tel:+33#{@action.user.phone.gsub(' ', '')}>#{@action.user.phone}"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Email :*\n<mailto:#{@action.user.email}>#{@action.user.email}"
                  }
                ]
              },
              {
                type: "section",
                text: {
                  type: "mrkdwn",
                  text: "👀 <@#{slack_moderator_id(@action.user)}> merci de vérifier ce compte !"
                }
              }
            ]
          }
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
