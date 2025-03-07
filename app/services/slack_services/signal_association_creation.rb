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
            type: "section",
            text: {
              type: "mrkdwn",
              text: ":pushpin: *Nom :* #{@user.full_name} (#{@user.postal_code}, #{@user.city})"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: ":telephone_receiver: *Contact :* #{contact_info}"
            }
          },
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "👀 <@#{slack_moderator_id(@user)}> merci de vérifier ce compte !"
            }
          },
          {
            type: "actions",
            elements: [{
              type: "button",
              text: {
                type: "plain_text",
                text: "Voir le profil",
                emoji: true
              },
              url: link_to_user(@user.id)
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
