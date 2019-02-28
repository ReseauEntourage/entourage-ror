module TourServices
  class SimplifiedTourFilter < TourServices::TourFilterWeb
    def set_tours
      @tours = Tour.includes(:simplified_tour_points)
                   .joins(:user)
                   .where(users: { organization_id: orgs })
    end

    def filter_box
      if box
        tours_with_point_in_box = SimplifiedTourPoint.within_bounding_box(box).select(:tour_id).distinct
        self.tours = self.tours.where(id: tours_with_point_in_box)
      end
    end
  end
end
