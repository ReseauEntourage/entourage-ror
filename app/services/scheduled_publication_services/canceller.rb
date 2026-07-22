module ScheduledPublicationServices
  class Canceller
    # @param scope :occurrence (default) cancels only this occurrence and still schedules
    #   the next one in the series; :series also deactivates the recurrence rule so no
    #   further occurrence is generated
    def initialize(scheduled_publication, scope: :occurrence)
      @scheduled_publication = scheduled_publication
      @scope = scope.to_sym
    end

    def cancel!
      PublishScheduledPublicationJob.cancel(scheduled_publication.id)

      # @caution must run before revert_publishable! - cancelling a post blanks its content
      # (see ChatMessage#content), so the next occurrence must be cloned while it's intact
      if scope == :series
        scheduled_publication.recurrence_rule&.update!(active: false)
      else
        ScheduledPublicationServices::RecurrenceGenerator.new(scheduled_publication).generate_next!
      end

      revert_publishable!
      scheduled_publication.update!(status: :cancelled)
    end

    private

    attr_reader :scheduled_publication, :scope

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
