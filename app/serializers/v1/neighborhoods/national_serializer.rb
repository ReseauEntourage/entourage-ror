module V1
  module Neighborhoods
    class NationalSerializer < ActiveModel::Serializer
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
        :unread_posts_count,
        :image_url,
        :interests,
        :ethics,
        :past_outings_count,
        :future_outings_count,
        :has_ongoing_outing,
        :address,
        :posts,
        :public,
        :national,
        :user,
        :outings,
        :future_outings,
        :ongoing_outings

      def name
        I18nSerializer.new(object, :name, lang).translation
      end

      def name_translations
        I18nSerializer.new(object, :name, lang).translations
      end

      def description
        ""
      end

      def description_translations
        { translation: "", original: "", from_lang: "fr", to_lang: "fr" }
      end

      def welcome_message
        nil
      end

      def member
        return false unless scope && scope[:user]

        if object.association(:join_requests).loaded?
          object.join_requests.any? { |jr| jr.user_id == scope[:user].id && jr.status == 'accepted' }
        else
          JoinRequest.where(joinable: object, user: scope[:user], status: :accepted).exists?
        end
      end

      def members
        []
      end

      def unread_posts_count
        0
      end

      def image_url
        object.image_url_with_size :high
      end

      def interests
        []
      end

      def ethics
        []
      end

      def past_outings_count
        0
      end

      def future_outings_count
        0
      end

      def has_ongoing_outing
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

      def posts
        []
      end

      def user
        {}
      end

      def outings
        []
      end

      def future_outings
        []
      end

      def ongoing_outings
        []
      end

      private

      def lang
        return unless scope && scope[:user] && scope[:user].lang

        scope[:user].lang
      end
    end
  end
end
