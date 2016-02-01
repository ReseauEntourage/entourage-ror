module TourServices
  class CloseTourService
    def initialize(tour:, params:)
      @tour = tour
      @params = params
    end

    def close!
      return if tour.closed?

      closed_at = tour.tour_points.last.try(:passing_time) || Time.now
      distance = params.try(:[], :distance).try(:to_f) || 0
      tour.status = "closed"
      tour.closed_at= closed_at
      tour.length = distance
      if tour.save
        MemberMailer.tour_report(tour).deliver_later
        SnapToRoadPolylineJob.perform_later(tour.id)
        SimplifyTourPointsJob.perform_later(tour.id)
      end
    end

    private
    attr_reader :tour, :params
  end
end