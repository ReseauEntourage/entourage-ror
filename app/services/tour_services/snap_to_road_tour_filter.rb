module TourServices
  class SnapToRoadTourFilter < TourServices::TourFilter
    def set_tours
      @tours = Tour.includes(:snap_to_road_tour_points)
                   .joins(:user)
                   .where(users: { organization_id: orgs })
    end

    def filter_box
      if box
        tours_with_point_in_box = SnapToRoadTourPoint.unscoped.within_bounding_box(box).select(:tour_id).distinct
        self.tours = self.tours.where(id: tours_with_point_in_box)
      end
    end
  end
end