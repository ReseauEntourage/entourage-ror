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
    return unless user = User.find_by(id: user_id)
    return if counter == UserStat::CONVERSATION_MEMBERS && staff?(user)

    UserStat.refresh!(user_id, counter)
  end

  private

  # Staff members converse with up to tens of thousands of members: their
  # conversation_members count takes seconds, above the statement timeout, and
  # is no impact to show. It keeps the value of the last backfill.
  def staff? user
    user.admin? || user.team?
  end
end
