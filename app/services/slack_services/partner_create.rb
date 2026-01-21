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
            type: "header",
            text: {
              type: "plain_text",
              text: "🏢 Une nouvelle association a été créée",
              emoji: true
            }
          },

          # Context
          {
            type: "context",
            elements: [
              {
                type: "mrkdwn",
                text: "*Utilisateur ayant créé l'association:* #{[@user.full_name, @user.email].compact.join(', ') if @user.present?}"
              },
              {
                type: "mrkdwn",
                text: "*Référent Slack:* <@#{slack_moderator_id(@user) if @user.present?}>"
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

          # Ligne de rappel / modération (équivalent à “merci de vérifier…”)
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: "Cette association a été créée, merci de vérifier ses informations."
            }
          },

          # Bouton
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
