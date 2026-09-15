class RefreshEngagementSegmentsJob < ApplicationJob
  queue_as :default

  def perform
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
    # stale forever.
    UserSegment.where.not(user_id: eligible_user_ids).find_each do |user_segment|
      EngagementSegmentApplier.call(
        user_id: user_segment.user_id,
        segment: nil,
        sub_segment: nil,
        computed_at: now,
        as_of: today
      )
    end
  end
end
