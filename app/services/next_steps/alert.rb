module NextSteps
  # Daily check of what the engine relies on (design.md, decision 13), run by
  # `rake next_steps:alert` on Heroku Scheduler. Warns Sentry when:
  # - no papotage is scheduled within 7 days: the fallback would be missing;
  # - the segments were last computed more than 2 days ago: the segments task
  #   failed or was refused (stale engagement data).
  module Alert
    PAPOTAGE_HORIZON = 7.days
    SEGMENTS_MAX_AGE = 2.days

    # @return [Array<String>] the warnings sent
    def self.call now: Time.zone.now
      warnings = []

      upcoming = Outing.active.where("metadata->>'starts_at' BETWEEN ? AND ?", now, now + PAPOTAGE_HORIZON)
      warnings << 'no papotage is scheduled within 7 days' if Papotages.ids(upcoming).empty?

      latest = UserSegment.maximum(:segment_computed_at)
      warnings << "engagement segments were last computed at #{latest || 'no date'}" if latest.nil? || latest < now - SEGMENTS_MAX_AGE

      warnings.each { |warning| Sentry.capture_message("next_steps: #{warning}", level: :warning) }
      warnings
    end
  end
end
