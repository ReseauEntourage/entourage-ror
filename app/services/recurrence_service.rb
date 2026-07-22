module RecurrenceService
  INTERVALS = { daily: 1.day, weekly: 1.week, monthly: 1.month }.freeze

  # @caution ActiveSupport::TimeWithZone arithmetic advances by calendar day/week/month
  # and keeps the local wall-clock time across a DST transition (e.g. 18:00 -> 18:00,
  # not a fixed 24h shift) - this is what keeps recurring occurrences at the same
  # advertised hour for users, through the Paris summer/winter time change
  def self.next_occurrence(time, frequency)
    interval = INTERVALS.fetch(frequency.to_sym)

    time.in_time_zone('Paris') + interval
  end
end
