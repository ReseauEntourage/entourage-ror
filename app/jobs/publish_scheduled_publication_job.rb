require 'sidekiq/api'

class PublishScheduledPublicationJob
  include Sidekiq::Worker
  # @caution reuses the existing `broadcast` queue (already consumed by worker_2, cf. Procfile)
  # instead of introducing a new queue that no deployed worker would listen to
  sidekiq_options retry: false, queue: :broadcast

  def perform(scheduled_publication_id)
    scheduled_publication = ScheduledPublication.find_by(id: scheduled_publication_id)
    return unless scheduled_publication&.pending?

    ScheduledPublicationServices::Publisher.new(scheduled_publication).publish!
  end

  def self.schedule(scheduled_publication)
    set(tags: [scheduled_publication.id]).perform_at(scheduled_publication.scheduled_at, scheduled_publication.id)
  end

  def self.scheduled_set
    Sidekiq::ScheduledSet.new
  end

  def self.cancel(scheduled_publication_id)
    scheduled_set.select { |job| job.tags.include?(scheduled_publication_id) }.each(&:delete)
  end
end
