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
               :number_of_people,
               :join_status

    has_many :tour_points
    has_one :author

    def distance
      object.length
    end

    def start_time
      object.created_at
    end

    def end_time
      object.closed_at
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

    def tour_points
      points = object.simplified_tour_points.present? ? object.simplified_tour_points : object.tour_points
      JSON.parse(ActiveModel::ArraySerializer.new(points, each_serializer: ::V1::TourPointSerializer).to_json)
    end

    def join_status
      if current_tour_user
        current_tour_user.status
      else
        "not_requested"
      end
    end

    def current_tour_user
      object.tours_users.select {|tour_user| tour_user.user_id == scope.id}.first
    end
  end
end