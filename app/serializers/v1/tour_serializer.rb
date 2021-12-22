module V1
  class TourSerializer < ActiveModel::Serializer
    include AmsLazyRelationships::Core

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

    has_many :tour_points
    has_one :author
    has_one :last_message, if: :include_last_message?

    lazy_relationship :last_chat_message
    lazy_relationship :chat_messages_count
    lazy_relationship :chat_messages
    lazy_relationship :join_requests

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
          partner: nil
      }
    end

    def organization_description
      object.organization_description
    end

    def tour_points
      TourPointsServices::TourPointsSimplifier.new(tour_id: object.id).simplified_tour_points
    end

    def join_status
      current_join_request&.simplified_status || "not_requested"
    end

    def number_of_unread_messages
      if current_join_request.nil?
        nil
      elsif scope.key?(:number_of_unread_messages)
        scope[:number_of_unread_messages]
      elsif current_join_request.status != 'accepted'
        0
      elsif current_join_request.last_message_read.nil?
        lazy_chat_messages_count&.count || 0
      else
        lazy_chat_messages.select do |chat_message|
          chat_message.created_at > current_join_request.last_message_read
        end.count
      end
    end

    def current_join_request
      @current_join_request ||= begin
        if scope[:user].nil?
          nil
        elsif scope.key?(:current_join_request)
          scope[:current_join_request]
        else
          # @fixme performance issue: we instanciate all records but we need only one
          lazy_join_requests.select do |join_request|
            join_request.user_id == scope[:user].id
          end.first
        end
      end
    end
  end
end
