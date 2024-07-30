module V1
  module Neighborhoods
    class MainListSerializer < ActiveModel::Serializer
    # les champs qui sont nécessaires sont
    # #
    # uuid: Int
    # name: String
    # unread_posts_count: Int?
    # image_url: String?
    # future_outings_count: Int
    # members_count: Int
    # #
    # et les champs que tu peux fake car non nécessaire, mais que apparement on peut pas changer
    # #
    # uuid_v2: String
    # members: [MemberLight]
    # creator: MemberLight
    # past_outings_count: Int
    # has_ongoing_outing: Bool
    # isMember: Bool
    # isSelected: Bool
      attributes :id,
        :uuid,
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
        :past_outings_count,
        :future_outings_count,
        :has_ongoing_outing,

      has_one :user, serializer: ::V1::Users::BasicSerializer

      def user
        # fake data: not used in mobile app
        {}
      end

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
