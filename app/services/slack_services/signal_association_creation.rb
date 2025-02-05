module SlackServices
  class SignalAssociationCreation < Notifier
    def initialize user:
      @user = user
    end

    def env
      ENV['SLACK_SIGNAL']
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
                    text: "*Nom :*\n#{@user.full_name}"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Accéder au profil :*\n<#{link_to_user(@user_id)}|Cliquez ici>"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Contact :*\n<tel:+33#{@user.phone.gsub(' ', '')}>#{@user.phone}"
                  },
                  {
                    type: "mrkdwn",
                    text: "*Email :*\n<mailto:#{@user.email}>#{@user.email}"
                  }
                ]
              },
              {
                type: "section",
                text: {
                  type: "mrkdwn",
                  text: "👀 <@#{slack_moderator_id(@user)}> merci de vérifier ce compte !"
                }
              }
            ]
          }
        ]
      }
    end

    def payload_adds
      {
        username: "Création d’un compte association",
        channel: webhook('channel-associations'),
      }
    end
  end
end
