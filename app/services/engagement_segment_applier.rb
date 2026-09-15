# Writes one user's computed segment into `user_segments` (current state)
# and `user_segment_history` (transition log), appending a history row
# only when the segment or sub-segment actually changed. Shared by the
# live nightly job and the one-off historical backfill, so both write
# history the same way.
class EngagementSegmentApplier
  def self.call(user_id:, segment:, sub_segment:, computed_at:, as_of:)
    ActiveRecord::Base.transaction do
      user_segment = UserSegment.find_or_initialize_by(user_id: user_id)
      user_segment.engagement_segment = segment
      user_segment.engagement_sub_segment = sub_segment
      user_segment.segment_computed_at = computed_at
      user_segment.save!

      open_history = UserSegmentHistory.open.find_by(user_id: user_id)

      next if open_history &&
        open_history.engagement_segment == segment &&
        open_history.engagement_sub_segment == sub_segment

      if open_history && open_history.valid_from == as_of
        # Already amended today (or this backfilled day): update in place
        # instead of violating the one-row-per-user-per-day index.
        open_history.update!(engagement_segment: segment, engagement_sub_segment: sub_segment, computed_at: computed_at)
      else
        open_history&.update!(valid_to: as_of)

        UserSegmentHistory.create!(
          user_id: user_id,
          engagement_segment: segment,
          engagement_sub_segment: sub_segment,
          valid_from: as_of,
          computed_at: computed_at
        )
      end
    end
  end
end
