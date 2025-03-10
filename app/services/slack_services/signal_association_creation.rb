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

      options = partners.map { |partner|
        {
          text: {
            type: "plain_text",
            text: partner.name,
            emoji: true
          },
          value: "partner-id-#{partner.id}"
        }
      }

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
          },
          {
            type: "input",
            element: {
              type: "static_select",
              placeholder: {
                type: "plain_text",
                text: "Sélectionner l'association",
                emoji: true
              },
              options: options,
              action_id: "static_select-action"
            },
            label: {
              type: "plain_text",
              text: "Choisir",
              emoji: true
            }
          },
          {
            type: "actions",
            elements: [{
              type: "button",
              text: {
                type: "plain_text",
                text: "N'est pas une association",
                emoji: true
              },
              url: link_to_user(@user.id)
            }]
          },
        ]
      }
    end

    def payload_adds
      {
        username: "Création d’un compte association",
        channel: webhook('channel-associations'),
      }
    end

    private

    def partners
      return [] unless @user.latitude && @user.longitude

      bounding_box_sql = Geocoder::Sql.within_bounding_box(*box, :latitude, :longitude)

      Partner.where(bounding_box_sql).order(:name)
    end

    def box
      # Geocoder::Calculations.bounding_box([@user.latitude, @user.longitude], @user.travel_distance, units: :km)
      Geocoder::Calculations.bounding_box([@user.latitude, @user.longitude], 100, units: :km)
    end
  end
end
