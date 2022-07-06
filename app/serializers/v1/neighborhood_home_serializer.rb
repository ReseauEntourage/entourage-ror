module V1
  class NeighborhoodHomeSerializer < ActiveModel::Serializer
    attributes :id,
      :name,
      :description,
      :welcome_message,
      :member,
      :members_count,
      :image_url,
      :interests,
      :ethics,
      :past_outings_count,
      :future_outings_count,
      :has_ongoing_outing,
      :address,
      :posts

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_many :members, serializer: ::V1::Users::BasicSerializer
    has_many :future_outings, serializer: ::V1::OutingSerializer
    has_many :ongoing_outings, serializer: ::V1::OutingSerializer

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def interests
      object.interest_list.sort
    end

    def has_ongoing_outing
      object.has_ongoing_outing?
    end

    def address
      {
        latitude: object.latitude,
        longitude: object.longitude,
        street_address: object.street_address,
        display_address: [object.place_name, object.postal_code].compact.uniq.join(', ')
      }
    end

    def posts
      object.parent_chat_messages.ordered.limit(25).map do |chat_message|
        V1::ChatMessageSerializer.new(chat_message, scope: { current_join_request: current_join_request }).as_json
      end
    end

    private

    def current_join_request
      return unless scope[:user]

      @current_join_request ||= JoinRequest.where(joinable: object, user: scope[:user], status: :accepted).first
    end
  end
end
