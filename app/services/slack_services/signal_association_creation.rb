module SlackServices
  class SignalAssociationCreation < Notifier
    def initialize(user:)
      @user = user
    end

    def env
      ENV['SLACK_SIGNAL']
    end

    def payload
      contact_info = @user.phone
      contact_info += " - #{@user.email}" if @user.email.present?

      {
        blocks: [
          { type: "divider" },
          {
            type: "context",
            elements: [{
              type: "mrkdwn",
              text: ":pushpin: *Nom :* #{@user.full_name}"
            }]
          },
          {
            type: "context",
            elements: [{
              type: "mrkdwn",
              text: ":link: *Accéder au profil :* <#{link_to_user(@user.id)}|Cliquez ici>"
            }]
          },
          {
            type: "context",
            elements: [{
              type: "mrkdwn",
              text: ":telephone_receiver: *Contact :* #{contact_info}"
            }]
          },
          {
            type: "context",
            elements: [{
              type: "mrkdwn",
              text: "👀 <@#{slack_moderator_id(@user)}> merci de vérifier ce compte !"
            }]
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
