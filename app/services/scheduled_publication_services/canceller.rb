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
      return raise NotImplementedError, "cannot cancel a #{scheduled_publication.publishable_type}" unless scheduled_publication.post?

      scheduled_publication.publishable.update!(
        status: :deleted,
        deleter_id: scheduled_publication.author_id,
        deleted_at: Time.current
      )
    end
  end
end
