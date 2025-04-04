module V1
  module ChatMessages
    class GenericSerializer < ActiveModel::Serializer
      attributes :id,
                 :uuid_v2,
                 :content,
                 :content_html,
                 :content_translations,
                 :content_translations_html,
                 :user,
                 :created_at,
                 :post_id,
                 :has_comments,
                 :comments_count,
                 :image_url,
                 :read,
                 :message_type,
                 :status,
                 :survey

      def content
        return "" if object.deleted?
        return "" if object.offensive?

        Mentionable.no_html(
          I18nSerializer.new(object, :content, lang).translation
        )
      end

      def content_html
        return if object.deleted?

        I18nSerializer.new(object, :content, lang).translation
      end

      def content_translations
        return Hash.new if object.deleted?
        return Hash.new unless translations = I18nSerializer.new(object, :content, lang).translations
        return Hash.new unless translations.present?

        Mentionable.none_html!(translations)
      end

      def content_translations_html
        return Hash.new if object.deleted?

        I18nSerializer.new(object, :content, lang).translations
      end

      def user
        partner = object.user.partner

        {
          id: object.user.id,
          avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
          display_name: display_name,
          partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
          partner_role_title: object.user.partner_role_title.presence,
          roles: UserPresenter.new(user: object.user).public_targeting_profiles
        }
      end

      def display_name
        UserPresenter.new(user: object.user).display_name
      end

      def post_id
        object.parent_id
      end

      def has_comments
        object.comments_count > 0
      end

      def image_url
        object.image_url_with_size(image_size)
      end

      def read
        return unless current_join_request
        return false unless current_join_request.last_message_read.present?

        object.created_at <= current_join_request.last_message_read
      end

      def survey
        return unless object.survey

        V1::SurveySerializer.new(object.survey, root: false).as_json
      end

      private

      def current_join_request
        scope[:current_join_request]
      end

      def image_size
        return :medium unless scope

        scope[:image_size] || :medium
      end

      def lang
        return unless scope && scope[:user] && scope[:user].lang

        scope[:user].lang
      end
    end
  end
end
