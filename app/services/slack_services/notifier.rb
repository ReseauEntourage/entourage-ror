module SlackServices
  class Notifier
    def notify
      notifier&.ping payload.merge(payload_adds)
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
      "{}"
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

    def link_to_user user_id
      Rails.application.routes.url_helpers.admin_user_url(user_id, host: ENV['ADMIN_HOST'])
    end

    def link_to_group group
      Rails.application.routes.url_helpers.admin_entourage_url(group.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_neighborhood neighborhood
      Rails.application.routes.url_helpers.edit_admin_neighborhood_url(neighborhood.id, host: ENV['ADMIN_HOST'])
    end

    def link_to_conversation conversation_or_action
      if conversation_or_action.conversation?
        Rails.application.routes.url_helpers.admin_conversation_url(conversation_or_action.id, host: ENV['ADMIN_HOST'])
      else
        Rails.application.routes.url_helpers.admin_entourage_url(conversation_or_action.id, host: ENV['ADMIN_HOST'])
      end
    end
  end
end
