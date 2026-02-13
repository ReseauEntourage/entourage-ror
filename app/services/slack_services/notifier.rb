module SlackServices
  class Notifier
    attr_reader :slack_notification

    def notify
      return unless should_notify?

      notifier&.ping payload.merge(payload_adds)

      save_slack_notification
    end

    def notifier
      Slack::Notifier.new(url)
    end

    def url
      webhook 'url'
    end

    def webhook field
      return unless env.present?

      webhook = JSON.parse(env) rescue nil

      return unless webhook.present?

      webhook[field]
    end

    def env
      '{}'
    end

    def find_user user
      return user if user.is_a?(User)
      return AnonymousUserService.find_user_by_token(user, community: $server_community) if AnonymousUserService.token?(user, community: $server_community)

      OpenStruct.new(first_name: 'n/a', last_name: 'n/a', id: 'n/a')
    end

    def slack_moderator_id object
      ModerationServices.slack_moderator_id(object)
    end

    def departement object
      ModerationServices.departement(object)
    end

    def payload_adds
      {}
    end

    def link_to instance
      return link_to_user(instance.id) if instance.is_a?(User)
      return link_to_neighborhood(instance) if instance.is_a?(Neighborhood)
      return link_to_conversation(instance) if instance.is_a?(Entourage)
    end

    def link_to_user user_id
      Rails.application.routes.url_helpers.admin_user_url(user_id, host: ENV['ADMIN_HOST'])
    end

    def link_to_group group
      Rails.application.routes.url_helpers.admin_entourage_url(group.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_neighborhood neighborhood
      Rails.application.routes.url_helpers.edit_admin_neighborhood_url(neighborhood.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_partner partner
      Rails.application.routes.url_helpers.edit_admin_partner_url(partner.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_conversation conversation_or_action
      if conversation_or_action.conversation?
        Rails.application.routes.url_helpers.admin_conversation_url(conversation_or_action.id, host: ENV['ADMIN_HOST'])
      else
        Rails.application.routes.url_helpers.admin_entourage_url(conversation_or_action.id, host: ENV['ADMIN_HOST'])
      end
    end

    # By default, we send a notification if there is no existing one for the given context and instance.
    # This allows us to avoid sending multiple notifications for the same event (e.g., multiple comments on the same action).
    # If a notification already exists, we assume that it has already been sent and we do not send another one.
    def should_notify?
      return true unless slack_notification.present?

      slack_notification.new_record?
    end

    def set_slack_notification instance_type:, instance_id:, options: {}
      @slack_notification = SlackNotification
        .where('created_at >= ?', Time.current.beginning_of_day)
        .find_or_initialize_by(
          instance_type: instance_type,
          instance_id: instance_id,
          options: options,
          context: self.class.name.underscore
        )
    end

    def save_slack_notification
      return unless slack_notification.present?

      slack_notification.save!
    end
  end
end
