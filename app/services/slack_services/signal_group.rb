module SlackServices
  class SignalEntourage
    def initialize reported_group:, reporting_user:, message:
      @reported_group = reported_group
      @reporting_user = find_reporting_user(reporting_user)
      @message = message
    end

    def notify
      notifier&.ping payload.merge(payload_adds)
    end

    def notifier
      Slack::Notifier.new(webhook 'url')
    end

    def webhook field
      return unless ENV['SLACK_SIGNAL_GROUP_WEBHOOK'].present?

      webhook = JSON.parse(ENV['SLACK_SIGNAL_GROUP_WEBHOOK']) rescue nil

      return unless webhook.present?

      webhook[field]
    end

    def payload
      {
        text: "<@#{slack_moderator_id || 'clara'}> ou team modération (département : #{departement || 'n/a'}) pouvez-vous vérifier cet utilisateur ?",
        attachments: [
          {
            text: "Action, événement signalé : #{@reported_group.title} #{link_to_group(@reported_group)}"
          },
          {
            text: "Signalé par : #{@reporting_user.full_name} #{link_to_user(@reporting_user)}"
          },
          {
            text: "Message : #{@message}"
          },
        ]
      }
    end

    def payload_adds
      {
        username: webhook('username'),
        channel: webhook('channel'),
      }
    end

    private

    def find_reporting_user user
      return user if user.is_a?(User)
      return AnonymousUserService.find_user_by_token(user, community: $server_community) if AnonymousUserService.token?(user, community: $server_community)

      OpenStruct.new(first_name: 'n/a', last_name: 'n/a', id: 'n/a')
    end

    def slack_moderator_id
      moderation_area = ModerationServices.moderation_area_for_user(@reported_group)
      return moderation_area.slack_moderator_id if moderation_area.present?

      nil
    end

    def departement
      ModerationServices.departement_for_object @reported_group.address
    end

    def link_to_user user
      Rails.application.routes.url_helpers.admin_user_url(user.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_group group
      Rails.application.routes.url_helpers.admin_group_url(group.id, host: ENV['ADMIN_HOST'])
    end
  end
end
