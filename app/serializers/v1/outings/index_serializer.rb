module V1
  module Outings
    class IndexSerializer < ActiveModel::Serializer
      attributes :id,
        :uuid,
        :uuid_v2,
        :status,
        :title,
        :title_translations,
        :event_url,
        :author,
        :online,
        :metadata,
        :interests,
        :member,
        :members_count

      def title
        I18nSerializer.new(object, :title, lang).translation
      end

      def title_translations
        I18nSerializer.new(object, :title, lang).translations
      end

      def uuid
        object.uuid_v2
      end

      def author
        return unless user = object.user

        {
          id: user.id,
          community_roles: UserPresenter.new(user: user).public_targeting_profiles
        }
      end

      def member
        return false unless scope && scope[:user]

        member_ids.include?(scope[:user].id)
      end

      def metadata
        landscape_url = object.preload_image_url || object.image_url_with_size(object.landscape_url, :small)

        # portrait_url is not used but it is required by ios version
        return {
          starts_at: object.metadata[:starts_at],
          ends_at: object.metadata[:ends_at],
          display_address: object.metadata[:display_address],
          place_name: object.metadata[:place_name],
          street_address: object.metadata[:street_address],
          landscape_url: landscape_url,
          portrait_url: ""
        }
      end

      def interests
        # we use "Tag.interest_list &" to force ordering
        Tag.interest_list & object.interest_names
      end

      private

      def lang
        return unless scope && scope[:user] && scope[:user].lang

        scope[:user].lang
      end

      def member_ids
        object.preload_member_ids || object.member_ids
      end
    end
  end
end
