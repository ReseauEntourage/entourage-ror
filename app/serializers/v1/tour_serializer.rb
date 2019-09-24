module V1
  class TourSerializer < ActiveModel::Serializer
    include V1::Myfeeds::LastMessage

    attributes :id,
               :uuid,
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

    has_many :tour_points, serializer: ActiveModel::DefaultSerializer
    has_one :author, serializer: ActiveModel::DefaultSerializer
    has_one :last_message, serializer: ActiveModel::DefaultSerializer

    def filter(keys)
      include_last_message? ? keys : keys - [:last_message]
    end

    def uuid
      object.id.to_s
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
      # TODO(partner)
      {
          id: tour_author.id,
          display_name: UserPresenter.new(user: object.user).display_name,
          avatar_url: UserServices::Avatar.new(user: tour_author).thumbnail_url,
          partner: nil # object.user.partner.nil? ? nil : V1::PartnerSerializer.new(object.user.partner, scope: {user: object.user}, root: false).as_json
      }
    end

    def organization_description
      object.organization_description
    end

    def tour_points
      TourPointsServices::TourPointsSimplifier.new(tour_id: object.id).simplified_tour_points
    end

    def join_status
      if current_join_request
        current_join_request.status
      else
        "not_requested"
      end
    end

    def number_of_unread_messages
      if current_join_request.nil?
        nil
      elsif scope.key?(:number_of_unread_messages)
        scope[:number_of_unread_messages]
      elsif current_join_request.status != 'accepted'
        0
      elsif current_join_request.last_message_read.nil?
        object.chat_messages.count
      else
        object.chat_messages.where("created_at > ?", current_join_request.last_message_read).count
      end
    end

    def current_join_request
      if scope[:user].nil?
        nil
      elsif scope.key?(:current_join_request)
        scope[:current_join_request]
      elsif object.join_requests.loaded?
        object.join_requests.select {|join_request| join_request.user_id == scope[:user].id}.first
      else
        JoinRequest.where(user_id: scope[:user].id, joinable: object).first
      end
    end
  end
end
