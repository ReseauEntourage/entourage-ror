# One-off, manually-triggered job (not scheduled) that reconstructs
# `user_segments` / `user_segment_history` for days before this feature
# existed, replaying EngagementSegmentComputation day by day in
# chronological order and writing through EngagementSegmentApplier - the
# same "only write history on change" logic the live nightly job uses.
#
# Eligibility for backfilled days uses `session_histories` instead of
# `users.last_sign_in_at` (see EngagementSegmentComputation) - the closest
# available reconstruction of "signed in in the last 30 days" for a date
# that isn't today. `login_histories` would be the more literal analogue
# of "signed in", but a real-data check (2026-09-16) showed it stopped
# being written to in December 2020 - it would silently make every user
# ineligible for any recent backfill period. `targeting_profile`/`deleted`
# are read at their *current* value throughout, since neither is
# historized.
#
# The reconstructed range is clamped to what the source data can actually
# support: a full 30-day trailing window of `denorm_daily_engagements_with_type`
# needs to exist before the first reconstructed day, and `session_histories`
# needs to still be an actively-written table - guarded explicitly, given
# `login_histories` already failed this exact way once. Run via:
#   BackfillEngagementSegmentsJob.perform_now(months: 6)
class BackfillEngagementSegmentsJob < ApplicationJob
  queue_as :default

  STALE_SOURCE_THRESHOLD = 7.days

  def perform(months: 6)
    end_date = Date.yesterday # today is the live job's job to compute
    requested_start = months.months.ago.to_date

    earliest_engagement = DenormDailyEngagementsWithType.minimum(:date)
    earliest_session = SessionHistory.minimum(:date)
    latest_session = SessionHistory.maximum(:date)

    return if earliest_engagement.nil? || earliest_session.nil?

    if latest_session < STALE_SOURCE_THRESHOLD.ago.to_date
      raise "session_histories looks stale (latest row: #{latest_session}) - it may no longer be a " \
        "reliable substitute for eligibility, the same way login_histories silently stopped being " \
        "written to in December 2020. Re-check before relying on it for a backfill."
    end

    earliest_reliable_day = [earliest_engagement + 30.days, earliest_session].max
    start_date = [requested_start, earliest_reliable_day].max

    return if start_date > end_date

    (start_date..end_date).each { |as_of| replay_day(as_of) }
  end

  private

  def replay_day(as_of)
    computed_at = as_of.to_time.end_of_day
    results = EngagementSegmentComputation.call(as_of: as_of, eligibility: :session_histories)
    eligible_user_ids = results.map(&:user_id)

    results.each do |result|
      EngagementSegmentApplier.call(
        user_id: result.user_id,
        segment: result.segment,
        sub_segment: result.sub_segment,
        computed_at: computed_at,
        as_of: as_of
      )
    end

    UserSegment.where.not(user_id: eligible_user_ids).find_each do |user_segment|
      EngagementSegmentApplier.call(
        user_id: user_segment.user_id,
        segment: nil,
        sub_segment: nil,
        computed_at: computed_at,
        as_of: as_of
      )
    end
  end
end
