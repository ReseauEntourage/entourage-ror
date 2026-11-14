module NextSteps
  # Retention of the engine's own history (design.md, decision 14): next steps
  # and interactions are kept 6 months from their creation, and deleted with
  # the account. Domain data (joins, reads, Bonnes ondes requests) is never
  # touched: the exclusions built on it do not change.
  class Purge
    RETENTION = 6.months
    BATCH_SIZE = 1_000

    # Daily task (Heroku Scheduler): deletes, in batches, what is older than
    # the retention. Each table follows its own dates; the interactions have no
    # foreign key on next_steps.
    # @return [Hash] rows deleted per table
    def self.expired now: Time.zone.now
      cutoff = now - RETENTION

      {
        next_step_interactions: delete_in_batches(NextStepInteraction.where('created_at < ?', cutoff)),
        next_steps: delete_in_batches(NextStep.where('created_at < ?', cutoff))
      }
    end

    # A deleted or anonymized account: everything the engine kept about it.
    # @return [Hash] rows deleted per table
    def self.for_user user_id
      {
        next_step_interactions: NextStepInteraction.where(user_id: user_id).delete_all,
        next_steps: NextStep.where(user_id: user_id).delete_all
      }
    end

    def self.delete_in_batches scope
      total = 0

      loop do
        deleted = scope.model.where(id: scope.order(:id).limit(BATCH_SIZE).select(:id)).delete_all
        total += deleted
        break if deleted < BATCH_SIZE
      end

      total
    end
    private_class_method :delete_in_batches
  end
end
