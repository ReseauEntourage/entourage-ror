module V1
  module Neighborhoods
    class MainListSerializer < ActiveModel::Serializer
      attributes :id,
        :uuid_v2,
        :name,
        :name_translations,
        :description,
        :description_translations,
        :member,
        :members,
        :members_count,
        :unread_posts_count,
        :image_url,
        :future_outings_count

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

      # this serializer is used for neighborhoods in which the user is not a member
      def member
        false
      end

      def members
        # fake data: not really used in mobile app
        # but to assure retrocompatibility with former app versions, we need this method to be compatible with "members.size"
        # so we want this method to return an array of "members" elements
        Array.new([object.members_count, 99].min, { id: 1, lang: "fr", avatar_url: "n/a", display_name: "n/a" })
      end

      # no unread posts: this serializer is used for neighborhoods in which the user is not a member
      def unread_posts_count
        0
      end

      def image_url
        object.image_url_with_size :medium
      end

      private

      def lang
        return unless scope && scope[:user] && scope[:user].lang

        scope[:user].lang
      end
    end
  end
end
