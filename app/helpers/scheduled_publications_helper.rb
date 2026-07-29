module ScheduledPublicationsHelper
  # @caution distance_of_time_in_words returns a bare duration ("6 jours") regardless of
  # direction - callers used to always prefix it with "dans", which reads backwards for a
  # publication stuck pending past its scheduled_at (e.g. a delayed worker) or for a failed one
  def scheduled_countdown(scheduled_at)
    return "aujourd'hui" if scheduled_at.to_date == Time.zone.now.to_date
    return "en retard de #{distance_of_time_in_words(scheduled_at, Time.zone.now)}" if scheduled_at.past?

    "dans #{distance_of_time_in_words(Time.zone.now, scheduled_at)}"
  end
end
