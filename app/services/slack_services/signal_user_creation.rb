module SlackServices
  class SignalUserCreation
    attr_accessor :user, :blocked_user_ids

    def initialize user:, blocked_user_ids:
      @user = user
      @blocked_user_ids = blocked_user_ids
    end

    def notify
      notifier&.ping payload.merge(payload_adds)
    end

    def notifier
      Slack::Notifier.new(webhook 'url')
    end

    def webhook field
      return unless ENV['SLACK_SIGNAL_USER_WEBHOOK'].present?

      webhook = JSON.parse(ENV['SLACK_SIGNAL_USER_WEBHOOK']) rescue nil

      return unless webhook.present?

      webhook[field]
    end

    def payload
      {
        text: "Un utilisateur a créé un compte avec le même email qu'un compte bloqué. Merci de vérifier cet utilisateur.",
        attachments: [{
          text: "Compte créé : #{user.full_name}, #{link_to_user user.id}"
        }] + blocked_user_ids.map { |blocked_user_id|
          { text: "Utilisateur bloqué : #{link_to_user blocked_user_id }"}
        }
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end

    private

    def link_to_user user_id
      Rails.application.routes.url_helpers.admin_user_url(user_id, host: ENV['ADMIN_HOST'])
    end
  end
end
