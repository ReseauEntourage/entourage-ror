module SlackServices
  class PartnerUpdate < Notifier
    TRACKED_ATTRIBUTES = %w[name description image_url].freeze

    def initialize user:, partner:
      @user = user
      @partner = partner
    end

    def notify
      return unless should_notify?

      super
    end

    def env
      ENV['SLACK_APP_WEBHOOKS']
    end

    def payload
      changes_text = changes.map { |attribute, (before, after)|
        if attribute == 'image_url'
          { text: "Nouveau logo :", image_url: @partner.image_url_with_size(:small) }
        else
          { text: "Nouveau #{attribute} : #{after}" }
        end
      }

      {
        text: "Une association a modifié ses informations",

        attachments: [{
          text: "Utilisateur ayant modifié l'association : #{[@user.full_name, @user.email].compact.join(', ')} #{link_to_user(@user.id)}"
        }, {
          text: "Association concernée : #{link_to_partner(@partner)}"
        }, {
          text: "Référent modé : <@#{slack_moderator_id(@user)}> (département : #{departement(@user) || 'n/a'})"
        }] + changes_text + [{
          text: "👉 Merci de vérifier les informations renseignées !"
        }]
      }
    end

    def payload_adds
      {
        username: "Mise à jour d'une association",
        channel: url,
      }
    end

    private

    def should_notify?
      (changes.keys & TRACKED_ATTRIBUTES).any?
    end

    def changes
      @changes ||= @partner.previous_changes.slice(*TRACKED_ATTRIBUTES)
    end

    def url
      config = JSON.parse(env) rescue nil
      return unless config.present?

      channel = config['default']
      channel = config[@partner.postal_code.first(2)] if @partner.postal_code.present?

      config['prefix'] + channel
    end
  end
end
