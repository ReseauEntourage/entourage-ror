module V1
  class NeighborhoodHomeSerializer < ActiveModel::Serializer
    OUTINGS_LIMIT = 10
    POSTS_LIMIT = 25

    attributes :id,
      :uuid_v2,
      :name,
      :name_translations,
      :description,
      :description_translations,
      :welcome_message,
      :member,
      :members,
      :members_count,
      :image_url,
      :interests,
      :ethics,
      :past_outings_count,
      :future_outings_count,
      :has_ongoing_outing,
      :address,
      :posts,
      :public

    has_one :user, serializer: ::V1::Users::BasicSerializer
    has_many :outings, serializer: ::V1::OutingSerializer
    has_many :future_outings, serializer: ::V1::OutingSerializer
    has_many :ongoing_outings, serializer: ::V1::OutingSerializer

    def name
      I18nSerializer.new(object, :name, lang).translation
    end

    def name_translations
      I18nSerializer.new(object, :name, lang).translations
    end

    def description
      I18nSerializer.new(object, :description, lang).translation
    end

    def description_translations
      I18nSerializer.new(object, :description, lang).translations
    end

    def member
      return false unless scope && scope[:user]

      object.members.include? scope[:user]
    end

    def members
      # fake data: not really used in mobile app
      # but to assure retrocompatibility with former app versions, we need this method to be compatible with "members.size"
      # so we want this method to return an array of "members" elements
      Array.new(object.members_count, { id: 1, avatar_url: "n/a", display_name: "n/a" })
    end

    def interests
      object.interest_names.sort
    end

    def past_outings_count
      # fake data: not used in mobile app
      0
    end

    def has_ongoing_outing
      # fake data: not used in mobile app
      false
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

    def lang
      return unless scope && scope[:user] && scope[:user].lang

      scope[:user].lang
    end
  end
end
