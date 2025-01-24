module V1
  module Resources
    class GenericSerializer < ActiveModel::Serializer
      attributes :id,
        :uuid_v2,
        :name,
        :is_video,
        :duration,
        :category,
        :description,
        :image_url,
        :url,
        :watched,
        :html

      def name
        I18nSerializer.new(object, :name, lang).translation
      end

      def description
        I18nSerializer.new(object, :description, lang).translation
      end

      def watched
        return false unless scope[:user].present?

        scope[:user].has_watched_resource?(object.id)
      end

      def nohtml?
        scope[:nohtml]
      end

      def html
        ResourceServices::Format.new(resource: object, lang: lang).to_html
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
