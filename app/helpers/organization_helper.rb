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
  
  def meters_to_printable_km(meters)
    km = (meters / 1000.0).round(1)
    kmi = km.to_f
    km = kmi if km == kmi
    "#{km}"
  end
  
  def marker_index(index)
    return (index + 1).to_s if index < 9
    return ('A'.ord + index - 9).chr if index < 35
    return '?'
  end
end