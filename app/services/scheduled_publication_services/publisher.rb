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
    ensure
      # a failed occurrence must not stop the series - the next one is scheduled regardless
      ScheduledPublicationServices::RecurrenceGenerator.new(scheduled_publication).generate_next!
    end

    private

    attr_reader :scheduled_publication

    def notify_author!(text)
      SlackServices::DirectMessage.new(user: scheduled_publication.author, text: text).send!
    end

    def success_message
      if scheduled_publication.post?
        "Votre post dans #{scheduled_publication.neighborhood&.name} a été publié : #{admin_link}"
      else
        "Votre diffusion vers #{scheduled_publication.publishable.recipient_ids.count} groupes a été envoyée : #{admin_link}"
      end
    end

    def failure_message
      "Échec de la publication de votre publication programmée : #{admin_link}"
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
