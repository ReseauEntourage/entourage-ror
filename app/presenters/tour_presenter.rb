class TourPresenter
  include ActionView::Helpers
  delegate :id,
           :tour_type,
           :status,
           :vehicle_type,
           :organization_name,
           :organization_description,
           :length,
           :user_id,
           to: :tour

  def initialize(tour:)
    @tour = tour
  end

  def snap_to_road_points
    tour.snap_to_road_tour_points.map {|point| {long: point.longitude, lat: point.latitude} }
  end

  def tour_points
    tour.tour_points.map {|point| {long: point.longitude, lat: point.latitude} }
  end

  def simplified_tour_points
    tour.simplified_tour_points.map {|point| {long: point.longitude, lat: point.latitude} }
  end

  def can_see_detail?
    Authentication::UserTourAuthenticator.new(user: current_user, tour: @tour).allowed_to_see?
  end

  def duration
    if tour.duration < 3600
      distance_of_time_in_words(tour.duration)
    else
      hours = tour.duration/3600
      minutes = (tour.duration % 3600)/60
      "#{pluralize(hours, "heure")} #{pluralize(minutes, "minute")}"
    end
  end

  def distance
    number_to_human(tour.length, precision: 4, units: {unit: "m", thousand: "km"})
  end

  def tour_summary
    summary_text = "#{tour.user.full_name} a réalisé une maraude de #{duration}"
    summary_text += "et a rencontré #{pluralize tour.encounters.size, 'personne'}" if tour.encounters.size > 0
    link_to summary_text, Rails.application.routes.url_helpers.tour_path(tour)
  end

  def start_time
    @start_time ||= tour.tour_points.first.try(:passing_time).try(:strftime, "%H:%M")
  end

  def end_time
    @end_time ||= tour.tour_points.last.try(:passing_time).try(:strftime, "%H:%M")
  end

  private
  attr_reader :tour
end