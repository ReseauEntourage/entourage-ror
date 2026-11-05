# Runs after the engagement data it reads: `denorm_daily_engagements_with_type`
# is filled by the user-engagement AWS Lambda (entourage-tasks, `aggregate`,
# daily at 05:00 UTC), and `rake users:engagement_segments` is scheduled at
# 06:00 UTC on Heroku Scheduler.
#
# If that data stops before yesterday, the pipeline is down: computing anyway
# would see every user's engagement dry up, turn them Silencieux and record
# transitions that never happened. The run is refused instead, leaving every
# segment and `segment_computed_at` untouched.
class RefreshEngagementSegmentsJob < ApplicationJob
  class StaleEngagementDataError < StandardError; end

  queue_as :default

  def perform
    ensure_engagement_data_is_fresh!

    now = Time.current
    today = now.to_date

    results = EngagementSegmentComputation.call
    eligible_user_ids = results.map(&:user_id)

    results.each do |result|
      EngagementSegmentApplier.call(
        user_id: result.user_id,
        segment: result.segment,
        sub_segment: result.sub_segment,
        computed_at: now,
        as_of: today
      )
    end

    # Users who dropped out of eligibility (inactive > 30 days, became
    # `team`, or got deleted) since the last run: reset to unclassified and
    # record the transition, instead of leaving their last known segment
    # stale forever. Rows already unclassified are skipped: there's no
    # transition left to record for them.
    UserSegment.where.not(engagement_segment: nil).where.not(user_id: eligible_user_ids).find_each do |user_segment|
      EngagementSegmentApplier.call(
        user_id: user_segment.user_id,
        segment: nil,
        sub_segment: nil,
        computed_at: now,
        as_of: today
      )
    end
  end

  private

  def ensure_engagement_data_is_fresh!
    latest = DenormDailyEngagementsWithType.maximum(:date)

    return if latest && latest >= Date.yesterday

    raise(
      StaleEngagementDataError,
      "denorm_daily_engagements_with_type stops at #{latest || 'no date'} - the " \
      'user-engagement Lambda (entourage-tasks, 05:00 UTC) looks down. Segments left untouched: run ' \
      '`rake users:engagement_segments` again once the data has caught up.'
    )
  end
end
