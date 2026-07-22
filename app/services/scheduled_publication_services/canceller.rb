module ScheduledPublicationServices
  class Canceller
    def initialize(scheduled_publication)
      @scheduled_publication = scheduled_publication
    end

    def cancel!
      PublishScheduledPublicationJob.cancel(scheduled_publication.id)
      revert_publishable!

      scheduled_publication.update!(status: :cancelled)
    end

    private

    attr_reader :scheduled_publication

    def revert_publishable!
      return cancel_chat_message! if scheduled_publication.post?
      return cancel_broadcast! if scheduled_publication.broadcast?

      raise NotImplementedError, "cannot cancel a #{scheduled_publication.publishable_type}"
    end

    def cancel_chat_message!
      scheduled_publication.publishable.update!(
        status: :deleted,
        deleter_id: scheduled_publication.author_id,
        deleted_at: Time.current
      )
    end

    def cancel_broadcast!
      scheduled_publication.publishable.update!(status: :draft, scheduled_at: nil)
    end
  end
end
