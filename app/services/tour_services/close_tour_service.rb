module TourServices
  class CloseTourService
    def initialize(tour:)
      @tour = tour
    end

    def close!
      return if tour.closed?

      closed_at = tour.tour_points.last.try(:passing_time) || Time.now
      if tour.update(status: "closed", closed_at: closed_at)
        MemberMailer.tour_report(tour).deliver_later
        SnapToRoadPolylineJob.perform_later(tour.id)
      end
    end

    private
    attr_reader :tour
  end
end