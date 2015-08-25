module OrganizationHelper
  def duration(tour)
    duration = tour.duration.to_i
    if duration < 60
      "#{duration} seconde".pluralize(duration)
    else
      duration_in_minutes = duration / 60
      hours = duration_in_minutes / 60
      minutes = duration_in_minutes % 60
      [].tap do |parts|
        parts << "#{hours} heure".pluralize(hours) if hours > 0
        parts << "#{minutes} minute".pluralize(minutes) if minutes > 0
      end.join(' ')
    end
  end
end