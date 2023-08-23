class TourPresenter
  attr_reader :tour

  include ActionView::Helpers
  delegate :id,
           :tour_type,
           :status,
           :vehicle_type,
           :organization_name,
           :organization_description,
           :length,
           :user_id,
           :created_at,
           to: :tour

  def initialize(tour:)
    @tour = tour
  end

  def tour_points
    tour.tour_points.ordered.map {|point| {long: point.longitude, lat: point.latitude} }
  end

  def simplified_tour_points
    tour.simplified_tour_points.ordered.map {|point| {long: point.longitude, lat: point.latitude} }
  end

  def can_see_detail?
    Authentication::UserTourAuthenticator.new(user: current_user, tour: @tour).allowed_to_see?
  end

  def duration(collection_cache=nil)
    if collection_cache
      duration = collection_cache.duration(tour)
    else
      duration = TourPoint.where(tour_id: tour.id).pluck(Arel.sql("extract(epoch from max(created_at) - min(created_at))")).first
    end

    return "-" if duration.nil?

    duration = duration.to_i
    if duration < 3600
      "environ "+distance_of_time_in_words(duration)
    else
      hours = duration/3600
      minutes = (duration % 3600)/60
      "#{pluralize(hours, "heure", "heures")} #{pluralize(minutes, "minute", "minutes")}"
    end
  end

  def distance
    number_to_human(tour.length, precision: 4, units: {unit: "m", thousand: "km"})
  end

  def tour_summary(current_user, collection_cache)
    summary_text = "#{tour.user.full_name} a réalisé une maraude de #{duration(collection_cache)}"
    encounters_count = collection_cache.encounters_count(tour)
    summary_text += " et a fait #{pluralize encounters_count, 'rencontre'}" if encounters_count > 0
    if Authentication::UserTourAuthenticator.new(user: current_user, tour: tour).allowed_to_see?
      link_to summary_text, Rails.application.routes.url_helpers.tour_path(tour)
    else
      summary_text
    end
  end

  def self.color(total:, current:)
    start_color = "1d5a13".to_i(16)
    end_color = "3db927".to_i(16)
    step = (end_color-start_color)/total
    "#"+(start_color + step*current).to_s(16)
  end

  def start_time
    @start_time ||= tour.created_at.try(:strftime, "%H:%M")
  end

  def end_time
    @end_time ||= tour.closed_at.try(:strftime, "%H:%M")
  end
end
