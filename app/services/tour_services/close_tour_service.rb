module TourServices
  class CloseTourService
    def initialize(tour:, params:)
      @tour = tour
      @params = params || {}
    end

    def close!
      return if tour.closed?

      closed_at = params[:end_time] || last_action_time || Time.now
      distance = params[:distance].try(:to_f) || 0
      tour.status = :closed
      tour.closed_at= closed_at
      tour.length = distance
      if tour.save
        SimplifyTourPointsJob.perform_later(tour.id, true)
      end
    end

    private
    attr_reader :tour, :params

    def last_action_time
      [tour.tour_points.maximum(:passing_time),
       tour.encounters.maximum(:date)]
      .compact
      .max
    end
  end
end