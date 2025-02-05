module SlackServices
  class SignalAssociationCreation < Notifier
    def initialize(user:)
      @user = user
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      {
        blocks: [
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: ":pushpin: *Nom :* #{@user.full_name}"
              },
              {
                type: "mrkdwn",
                text: ":link: *Accéder au profil :* <#{link_to_user(@user.id)}|Cliquez ici>"
              },
              {
                type: "mrkdwn",
                text: ":telephone_receiver: *Contact :* #{@user.phone}"
              }
            ].tap do |fields|
              if @user.email.present?
                fields << {
                  type: "mrkdwn",
                  text: ":email: *Email :* #{@user.email}"
                }
              end
            end
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
    end

    def payload_adds
      {
        username: "Création d’un compte association",
        channel: webhook('channel-associations'),
      }
    end
  end
end
