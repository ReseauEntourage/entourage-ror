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
               :join_status,
               :number_of_unread_messages,
               :updated_at

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
      tour_author = object.user
      {
          id: tour_author.id,
          display_name: tour_author.first_name,
          avatar_url: UserServices::Avatar.new(user: tour_author).thumbnail_url
      }
    end

    def organization_description
      object.organization_description
    end

    def tour_points
      points = object.simplified_tour_points.count > 0 ? object.simplified_tour_points.ordered : object.tour_points.ordered
      JSON.parse(ActiveModel::ArraySerializer.new(points, each_serializer: ::V1::TourPointSerializer).to_json)
    end

    def join_status
      if current_join_request
        current_join_request.status
      else
        "not_requested"
      end
    end

    def number_of_unread_messages
      return nil unless current_join_request
      return object.chat_messages.count if current_join_request.last_message_read.nil?
      object.chat_messages.where("created_at > ?", current_join_request.last_message_read).count
    end

    def current_join_request
      JoinRequest.where(user_id: scope.id, joinable: object).first
    end
  end
end