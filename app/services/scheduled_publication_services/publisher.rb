module ScheduledPublicationServices
  class Publisher
    def initialize(scheduled_publication)
      @scheduled_publication = scheduled_publication
    end

    def publish!
      publish_publishable!

      scheduled_publication.update!(status: :published)
      notify_author!(success_message)
    rescue => e
      Sentry.capture_exception(e)
      scheduled_publication.update!(status: :failed, failure_reason: e.message)
      notify_author!(failure_message)
    end

    private

    attr_reader :scheduled_publication

    def notify_author!(text)
      SlackServices::DirectMessage.new(user: scheduled_publication.author, text: text).send!
    end

    # copy: EN-9403-notifications-slack.md
    def success_message
      now = Time.current.in_time_zone('Paris')

      [
        "✅ Ta publication programmée vient d'être publiée",
        slack_title,
        "Publiée le #{now.strftime('%d/%m/%Y')} à #{now.strftime('%H:%M')} dans #{slack_cible}",
        "👉 <#{admin_link}|Voir la publication>"
      ].join("\n")
    end

    # copy: EN-9403-notifications-slack.md
    def failure_message
      scheduled_at = scheduled_publication.scheduled_at.in_time_zone('Paris')

      [
        "⚠️ Ta publication programmée n'a pas pu être publiée",
        slack_title,
        "Prévue le #{scheduled_at.strftime('%d/%m/%Y')} à #{scheduled_at.strftime('%H:%M')} dans #{slack_cible}",
        "Elle n'a pas été diffusée. Tu peux réessayer depuis le back-office.",
        "👉 <#{admin_link}|Ouvrir la publication>"
      ].join("\n")
    end

    def slack_title
      return scheduled_publication.publishable.content(true).to_s.truncate(80) if scheduled_publication.post?

      scheduled_publication.publishable.title
    end

    # {{cible}} : pour un post = « {{nom_du_groupe}} » ; pour une diffusion multi-groupes = « {{nombre}} groupes »
    def slack_cible
      return "« #{scheduled_publication.neighborhood&.name} »" if scheduled_publication.post?

      "« #{scheduled_publication.publishable.recipient_ids.count} groupes »"
    end

    def admin_link
      if scheduled_publication.post?
        Rails.application.routes.url_helpers.show_posts_admin_neighborhood_url(scheduled_publication.neighborhood_id, host: ENV['ADMIN_HOST'])
      else
        Rails.application.routes.url_helpers.edit_admin_neighborhood_message_broadcast_url(scheduled_publication.publishable_id, host: ENV['ADMIN_HOST'])
      end
    end

    def publish_publishable!
      return publish_chat_message! if scheduled_publication.post?
      return publish_broadcast! if scheduled_publication.broadcast?

      raise NotImplementedError, "cannot publish a #{scheduled_publication.publishable_type}"
    end

    def publish_chat_message!
      message = scheduled_publication.publishable
      now = Time.current

      message.update!(status: :active, created_at: now, updated_at: now)
    end

    # mirrors Admin::NeighborhoodMessageBroadcastsController#broadcast
    def publish_broadcast!
      broadcast = scheduled_publication.publishable
      broadcast.update!(status: :sent)

      ConversationMessageBroadcastJob.perform_later(
        broadcast.id,
        scheduled_publication.author_id,
        broadcast.content
      )
    end
  end
end
