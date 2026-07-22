module ScheduledPublicationServices
  class Publisher
    def initialize(scheduled_publication)
      @scheduled_publication = scheduled_publication
    end

    def publish!
      publish_publishable!

      scheduled_publication.update!(status: :published)
    rescue => e
      Sentry.capture_exception(e)
      scheduled_publication.update!(status: :failed, failure_reason: e.message)
    ensure
      # a failed occurrence must not stop the series - the next one is scheduled regardless
      ScheduledPublicationServices::RecurrenceGenerator.new(scheduled_publication).generate_next!
    end

    private

    attr_reader :scheduled_publication

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
