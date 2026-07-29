class UserStatsJob
  include Sidekiq::Worker

  # stats_has_changed! is a single atomic UPDATE, but two of these fired close
  # together for the same user (from two join_request events) have no
  # guaranteed completion order across connections, so the one started first
  # could finish last and overwrite a newer, correct result with a stale one.
  #
  # `lock: :until_executed` makes runs for the same user execute one at a time
  # instead of overlapping. `on_conflict: :reschedule` covers the remaining
  # case: a join_request change that arrives *while* a run for the same user
  # is already in flight would otherwise have its trigger silently dropped —
  # instead it's automatically re-enqueued once the current lock is released.
  sidekiq_options retry: true, queue: :default,
    lock: :until_executed,
    lock_args: ->(args) { args },
    on_conflict: :reschedule

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    user.stats_has_changed!
  end
end
