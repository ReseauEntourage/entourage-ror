module V1
  class TourSerializer < ActiveModel::Serializer
    attributes :id,
               :tour_type,
               :status,
               :vehicle_type,
               :distance,
               :organization_name,
               :organization_description,
               :start_time,
               :end_time,
               :number_of_people

    has_many :tour_points
    has_one :author

    def distance
      object.length
    end

    def start_time
      object.tour_points.first.try(:passing_time)
    end

    def end_time
      object.tour_points.last.try(:passing_time)
    end

    def organization_name
      object.organization_name
    end

    def author
      tour_user = object.user
      {
          id: tour_user.id,
          display_name: tour_user.first_name,
          avatar_url: nil
      }

    end

    def organization_description
      object.organization_description
    end
  end
end