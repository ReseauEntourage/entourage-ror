module V1
  class TourSerializer < ActiveModel::Serializer
    include V1::Myfeeds::LastMessage

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
    has_one :last_message

    def filter(keys)
      include_last_message? ? keys : keys - [:last_message]
    end

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
          avatar_url: UserServices::Avatar.new(user: tour_author).thumbnail_url,
          partner: object.user.default_partner.nil? ? nil : V1::PartnerSerializer.new(object.user.default_partner, scope: {user: object.user}, root: false).as_json
      }
    end

    def organization_description
      object.organization_description
    end

    def tour_points
      cache_points = $redis.get("entourage:tours:#{object.id}:tour_points")
      result = cache_points.present? ? JSON.parse(cache_points) : TourPointsServices::TourPointsSimplifier.new(tour_id: object.id).simplified_tour_points
      result.blank? ? object.tour_points : result
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
      JoinRequest.where(user_id: scope[:user]&.id, joinable: object).first
    end
  end
end