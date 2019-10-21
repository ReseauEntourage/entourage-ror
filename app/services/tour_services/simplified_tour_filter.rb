module TourServices
  class SimplifiedTourFilter < TourServices::TourFilterWeb
    def set_tours
      @tours = Tour.joins(:user)
                   .where(users: { organization_id: orgs })
    end

    def filter_box
      if box
        tour_ids = self.tours.pluck(:id)
        tour_ids_with_point_in_box = SimplifiedTourPoint.within_bounding_box(box).where(tour_id: tour_ids).uniq.pluck(:tour_id)
        self.tours = Tour.where(id: tour_ids_with_point_in_box)
      end
    end
  end
end
