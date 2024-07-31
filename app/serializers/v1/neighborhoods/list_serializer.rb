module V1
  module Neighborhoods
    class ListSerializer < ActiveModel::Serializer
      attributes :id,
        :uuid_v2,
        :name,
        :name_translations,
        :member,
        :members,
        :members_count,
        :unread_posts_count,
        :image_url,
        :past_outings_count,
        :future_outings_count,
        :has_ongoing_outing

      has_one :user, serializer: ::V1::Users::BasicSerializer

      def user
        # fake data: not used in mobile app
        nil
      end

      def name
        I18nSerializer.new(object, :name, lang).translation
      end

      def name_translations
        I18nSerializer.new(object, :name, lang).translations
      end

      def member
        raise NoMethodError, "You must implement member in a subclass"
      end

      def members
        # fake data: not really used in mobile app
        # but to assure retrocompatibility with former app versions, we need this method to be compatible with "members.size"
        # so we want this method to return an array of "members" elements
        Array.new([object.members_count, 99].min, { id: 1, lang: "fr", avatar_url: "n/a", display_name: "n/a" })
      end

      def unread_posts_count
        raise NoMethodError, "You must implement unread_posts_count in a subclass"
      end

      def image_url
        object.image_url_with_size :medium
      end

      def past_outings_count
        # fake data: not used in mobile app
        0
      end

      def has_ongoing_outing
        # fake data: not used in mobile app
        false
      end

      private

      def lang
        return unless scope && scope[:user] && scope[:user].lang

        scope[:user].lang
      end
    end
  end
end
