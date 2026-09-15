class RefreshEngagementSegmentsJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current
    today = now.to_date

    results = EngagementSegmentComputation.call
    eligible_user_ids = results.map(&:user_id)

    results.each do |result|
      apply(result.user_id, result.segment, result.sub_segment, now, today)
    end

    # Users who dropped out of eligibility (inactive > 30 days, became
    # `team`, or got deleted) since the last run: reset to unclassified and
    # record the transition, instead of leaving their last known segment
    # stale forever.
    UserSegment.where.not(user_id: eligible_user_ids).find_each do |user_segment|
      apply(user_segment.user_id, nil, nil, now, today)
    end
  end

  private

  def apply(user_id, segment, sub_segment, now, today)
    ActiveRecord::Base.transaction do
      user_segment = UserSegment.find_or_initialize_by(user_id: user_id)
      user_segment.engagement_segment = segment
      user_segment.engagement_sub_segment = sub_segment
      user_segment.segment_computed_at = now
      user_segment.save!

      open_history = UserSegmentHistory.open.find_by(user_id: user_id)

      next if open_history &&
        open_history.engagement_segment == segment &&
        open_history.engagement_sub_segment == sub_segment

      if open_history && open_history.valid_from == today
        # Job already ran (and changed something) today: amend today's
        # entry instead of violating the one-row-per-user-per-day index.
        open_history.update!(engagement_segment: segment, engagement_sub_segment: sub_segment, computed_at: now)
      else
        open_history&.update!(valid_to: today)

        UserSegmentHistory.create!(
          user_id: user_id,
          engagement_segment: segment,
          engagement_sub_segment: sub_segment,
          valid_from: today,
          computed_at: now
        )
      end
    end
  end
end
