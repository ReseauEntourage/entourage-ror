module SlackServices
  class PartnerCreate < Notifier
    def initialize(partner:)
      @partner = partner
      @user = partner.users.first
    end

    def env
      ENV["SLACK_SIGNAL"]
    end

    def payload
      {
        blocks: [
          # Title
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "*🏢 Une nouvelle association a été créée*",
            }
          },

          # Context
          {
            type: "context",
            elements: [
              {
                type: "mrkdwn",
                text: [
                  "*Utilisateur ayant créé l'association:* #{[@user.full_name, @user.email].compact.join(', ') if @user.present?}",
                  "*Référent Slack:* <@#{slack_moderator_id(@user) if @user.present?}>"
                ].join("\n")
              }
            ]
          },

          { type: "divider" },

          # Details
          {
            type: "section",
            fields: [
              {
                type: "mrkdwn",
                text: "*Nom de l'association :*\n#{@partner.name}"
              },
              {
                type: "mrkdwn",
                text: "*Téléphone :*\n#{@partner.phone || "—"}"
              }
            ]
          },

          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "Merci de vérifier ces informations."
            }
          },

          # Button
          {
            type: "actions",
            elements: [
              {
                type: "button",
                text: { type: "plain_text", text: "Voir l'utilisateur", emoji: true },
                url: "#{link_to_user(@user.id) if @user.present?}"
              },
              {
                type: "button",
                text: { type: "plain_text", text: "Voir l'association", emoji: true },
                url: link_to_partner(@partner)
              }
            ]
          }
        ]
      }
    end

    def payload_adds
      {
        username: "Création d'une association",
        channel: webhook("channel-associations")
      }
    end
  end
end
