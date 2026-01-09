module SlackServices
  class PartnerUpdate < Notifier
    def initialize user:, partner:
      @user = user
      @partner = partner
    end

    def env
      ENV['SLACK_APP_WEBHOOKS']
    end

    def payload
      changes_text = changes.map { |attribute, (before, after)|
        { text: "#{attribute} a changé : \n #{before} (avant) \n #{after} (après)" }
      }

      {
        text: "<@#{slack_moderator_id(@user)}> ou team modération (département : #{departement(@user) || 'n/a'}) L'utilisateur #{@user.full_name}, #{@email || '[Email non indiqué]'} a mis à jour l'association suivante. Merci d'en vérifier le contenu.",
        attachments: [{
          text: "Utilisateur : #{link_to_user(@user.id)}"
        }, {
          text: "Association : #{link_to_partner(@partner)}",
          image_url: @partner.image_url_with_size(:small)
        }] + changes_text
      }
    end

    def payload_adds
      {
        username: "Mise à jour d'une association",
        channel: url,
      }
    end

    private

    def changes
      changes = @partner.previous_changes.except("updated_at", "searchable_text")
    end

    def url
      config = JSON.parse(env) rescue nil
      return unless config.present?

      channel = config['default']
      channel = config[entourage.postal_code.first(2)] if entourage.country == 'FR' && entourage.postal_code.present?

      config['prefix'] + channel
    end
  end
end
