module ScheduledPublicationServices
  # Generates and schedules the next occurrence of a recurring series, one at a time
  # ("rolling" generation): only the next occurrence is ever materialized, created once
  # the current one is done with (published, failed, or skipped) - not the whole series
  # up front. This means cancelling the series simply stops generation instead of having
  # to clean up a batch of already-created future rows.
  class RecurrenceGenerator
    def initialize(scheduled_publication)
      @scheduled_publication = scheduled_publication
    end

    def generate_next!
      rule = scheduled_publication.recurrence_rule
      return unless rule&.active?

      next_at = RecurrenceService.next_occurrence(scheduled_publication.scheduled_at, rule.frequency)
      return if next_at.to_date > rule.ends_on

      next_scheduled_publication = ScheduledPublication.create!(
        publishable: clone_publishable!,
        neighborhood: scheduled_publication.neighborhood,
        author: scheduled_publication.author,
        recurrence_rule: rule,
        scheduled_at: next_at
      )
      PublishScheduledPublicationJob.schedule(next_scheduled_publication)

      next_scheduled_publication
    end

    private

    attr_reader :scheduled_publication

    def clone_publishable!
      return clone_chat_message! if scheduled_publication.post?

      clone_broadcast!
    end

    def clone_chat_message!
      original = scheduled_publication.publishable

      ChatMessage.create!(
        messageable: original.messageable,
        user: original.user,
        # force: true - by the time this runs the original may already be cancelled
        # (status: deleted), whose #content override blanks out the content
        content: original.content(true),
        message_type: original.message_type,
        status: :scheduled
      )
    end

    def clone_broadcast!
      cloned = scheduled_publication.publishable.clone
      cloned.status = :scheduled
      cloned.save!
      cloned
    end
  end
end
