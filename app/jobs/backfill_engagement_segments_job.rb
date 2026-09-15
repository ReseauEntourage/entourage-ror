# One-off, manually-triggered job (not scheduled) that reconstructs
# `user_segments` / `user_segment_history` for days before this feature
# existed, replaying EngagementSegmentComputation day by day in
# chronological order and writing through EngagementSegmentApplier - the
# same "only write history on change" logic the live nightly job uses.
#
# Eligibility for backfilled days uses `login_histories` instead of
# `users.last_sign_in_at` (see EngagementSegmentComputation) - the closest
# available reconstruction of "signed in in the last 30 days" for a date
# that isn't today. `targeting_profile`/`deleted` are read at their
# *current* value throughout, since neither is historized.
#
# The reconstructed range is clamped to what the source data can actually
# support: a full 30-day trailing window of `denorm_daily_engagements_with_type`
# needs to exist before the first reconstructed day, and at least one
# `login_histories` row needs to exist at all. Run via:
#   BackfillEngagementSegmentsJob.perform_now(months: 6)
class BackfillEngagementSegmentsJob < ApplicationJob
  queue_as :default

  def perform(months: 6)
    end_date = Date.yesterday # today is the live job's job to compute
    requested_start = months.months.ago.to_date

    earliest_engagement = DenormDailyEngagementsWithType.minimum(:date)
    earliest_login = LoginHistory.minimum(:connected_at)&.to_date

    return if earliest_engagement.nil? || earliest_login.nil?

    earliest_reliable_day = [earliest_engagement + 30.days, earliest_login].max
    start_date = [requested_start, earliest_reliable_day].max

    return if start_date > end_date

    (start_date..end_date).each { |as_of| replay_day(as_of) }
  end

  private

  def replay_day(as_of)
    computed_at = as_of.to_time.end_of_day
    results = EngagementSegmentComputation.call(as_of: as_of, eligibility: :login_histories)
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
