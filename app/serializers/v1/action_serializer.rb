module V1
  class ActionSerializer < ActiveModel::Serializer
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :uuid_v2,
               :status,
               :section,
               :title,
               :title_translations,
               :description,
               :description_translations,
               :image_url,
               :action_type,
               :author,
               :metadata,
               :member,
               :members_count,
               :created_at,
               :updated_at,
               :status_changed_at,
               :distance

    has_many :members, serializer: ::V1::Users::BasicSerializer
    has_one :location

    def title
      I18nSerializer.new(object, :title, lang).translation
    end

    def title_translations
      I18nSerializer.new(object, :title, lang).translations
    end

    def description
      I18nSerializer.new(object, :description, lang).translation
    end

    def description_translations
      I18nSerializer.new(object, :description, lang).translations
    end

    def uuid
      object.uuid_v2
    end

    def section
      object.section_list.first || ActionServices::Mapper.section_from_display_category(object.display_category)
    end

    def author
      return unless object.user.present?

      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        created_at: object.user.created_at
      }
    end

    def action_type
      object.contribution? ? :contribution : :solicitation
    end

    def member
      return false unless scope && scope[:user]

      object.member_ids.include?(scope[:user].id)
    end

    def metadata
      object.metadata_with_image_paths.except(:$id)
    end

    def image_url
      return unless object.image_url.present?
      return unless object.contribution?

      Contribution.image_url_for_with_size(object.image_url, :medium)
    end

    private

    def lang
      return unless scope && scope[:user] && scope[:user].lang

      scope[:user].lang
    end
  end
end
