module V1
  class ActionSerializer < ActiveModel::Serializer
    include V1::Entourages::Location

    attributes :id,
               :uuid,
               :status,
               :section,
               :title,
               :description,
               :image_url,
               :action_type,
               :author,
               :metadata,
               :member,
               :members_count,
               :created_at,
               :updated_at,
               :status_changed_at

    has_many :members, serializer: ::V1::Users::BasicSerializer
    has_one :location

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

      object.members.include? scope[:user]
    end

    def metadata
      object.metadata_with_image_paths.except(:$id)
    end

    def members_count
      object.accepted_members.count
    end

    def image_url
      return unless object.image_url.present?
      return unless object.contribution?

      Contribution.url_for(object.image_url)
    end
  end
end
