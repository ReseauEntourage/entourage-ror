module UserServices
  class Unblock
    def self.run!
      User.blocked.where('unblock_at is not null and unblock_at < ?', Time.now).pluck(:id).each do |user_id|
        notify user_id
      end
    end

    def self.notify user_id
      notifier&.ping(payload(user_id))
    end

    def self.notifier
      Slack::Notifier.new(webhook 'url')
    end

    def self.webhook field
      return unless ENV['SLACK_UNBLOCK_WEBHOOK'].present?

      webhook = JSON.parse(ENV['SLACK_UNBLOCK_WEBHOOK']) rescue nil

      return unless webhook.present?

      webhook[field]
    end

    def self.payload user_id
      return {} unless user = User.find(user_id)

      {
        text: "Le blocage temporaire de l'utilisateur #{user.full_name} arrive à échéance aujourd'hui, #{I18n.l user.unblock_at if user.unblock_at}",
        attachments: [
          {
            text: "Département : #{user.postal_codes.join(', ')}"
          },
          ({
            text: "L'utilisateur a été débloqué",
          } if true),
          {
            callback_id: [:user_unblock, user.id].join(':'),
            fallback: "",
            actions: [
              {
                text:  "Débloquer",
                type:  :button,
                style: :primary,
                name:  :action,
                value: :unblock,
                confirm: {
                  title:        "Débloquer cet utilisateur ?",
                  text:         "Il pourra de nouveau accéder à l'application Entourage",
                  ok_text:      "Oui",
                  dismiss_text: "Non"
                }
              },
              {

                text: "Afficher",
                type: :button,
                url: url_helper.admin_user_url(user.id, host: ENV['ADMIN_HOST'])
              }
            ]
          }
        ]
      }
    end

    private

    def self.url_helper
      Rails.application.routes.url_helpers
    end
  end
end
