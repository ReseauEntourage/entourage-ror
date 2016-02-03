module V0
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
               :user_id
    has_many :tour_points

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

    def organization_description
      object.organization_description
    end

    def tour_points
      points = object.simplified_tour_points.present? ? object.simplified_tour_points : object.tour_points
      JSON.parse(ActiveModel::ArraySerializer.new(points, each_serializer: ::V0::TourPointSerializer).to_json)
    end
  end
end