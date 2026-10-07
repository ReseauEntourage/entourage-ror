class UserImpactStatsJob
  include Sidekiq::Worker

  # Recomputes a single UserStat counter of a user.
  #
  # Triggered on every qualifying chat message, so bursts from the same user
  # (or from a mass sender such as a broadcast) must collapse:
  #   - `until_and_while_executing` locks from push until the job starts, so
  #     further pushes for the same user and counter are dropped while one is
  #     queued: that queued job has not run yet and will read the latest state;
  #   - it then locks while executing, and `server: :reschedule` re-enqueues a
  #     job starting while another one for the same user and counter is still
  #     running, so two recomputes never overlap and a stale result can never
  #     overwrite a newer one.
  # At most one queued and one running job per user and counter, no lost update.
  sidekiq_options retry: true, queue: :denorm,
    lock: :until_and_while_executing,
    lock_args: ->(args) { args },
    on_conflict: { client: :log, server: :reschedule }

  def perform(user_id, counter)
    raise ArgumentError, "unknown counter: #{counter}" unless UserStat.counter?(counter)
    return unless User.exists?(id: user_id)

    UserStat.refresh!(user_id, counter)
  end
end
