module V1
  class NeighborhoodSerializer < ActiveModel::Serializer
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
      :status_changed_at,
      :public

    has_one :user, serializer: ::V1::Users::BasicSerializer

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

    def image_url
      object.image_url_with_size :medium
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
        display_address: [object.place_name, object.postal_code].compact.uniq.join(', ')
      }
    end

    private

    def lang
      return unless scope && scope[:user] && scope[:user].lang

      scope[:user].lang
    end
  end
end
