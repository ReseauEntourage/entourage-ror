module V1
  class ResourceSerializer < ActiveModel::Serializer
    attributes :id,
      :uuid_v2,
      :name,
      :is_video,
      :duration,
      :category,
      :description,
      :image_url,
      :url,
      :watched

    attribute :html, unless: :nohtml?

    def name
      return object.name unless lang && object.translation

      object.translation.with_lang(lang).name || object.name
    end

    def description
      return object.description unless lang && object.translation

      object.translation.with_lang(lang).description || object.description
    end

    def watched
      return false unless scope[:user].present?

      UsersResource.find_by_resource_id_and_user_id_and_watched(object.id, scope[:user].id, true).present?
    end

    def nohtml?
      scope[:nohtml]
    end

    def html
      ResourceServices::Format.new(resource: object).to_html
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
