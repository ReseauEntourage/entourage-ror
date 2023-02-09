module V1
  class NeighborhoodHomeSerializer < ActiveModel::Serializer
    OUTINGS_LIMIT = 10
    POSTS_LIMIT = 25

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
    has_many :outings, serializer: ::V1::OutingSerializer
    has_many :future_outings, serializer: ::V1::OutingSerializer
    has_many :ongoing_outings, serializer: ::V1::OutingSerializer

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def interests
      object.interest_names.sort
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

    def image_url
      object.image_url_with_size :high
    end

    def posts
      object.parent_chat_messages.includes(:user).preload_comments_count.ordered.limit(POSTS_LIMIT).map do |chat_message|
        V1::ChatMessageHomeSerializer.new(chat_message, scope: { current_join_request: current_join_request }).as_json
      end
    end

    def outings
      object.outings_with_admin_online.active.future_or_ongoing.default_order.limit(OUTINGS_LIMIT)
    end

    def future_outings
      object.outings_with_admin_online.active.future_or_ongoing.default_order.limit(OUTINGS_LIMIT)
    end

    def ongoing_outings
      object.outings_with_admin_online(scope: :ongoing_outings).active.default_order.limit(OUTINGS_LIMIT)
    end

    private

    def current_join_request
      return unless scope[:user]

      @current_join_request ||= JoinRequest.where(joinable: object, user: scope[:user], status: :accepted).first
    end
  end
end
