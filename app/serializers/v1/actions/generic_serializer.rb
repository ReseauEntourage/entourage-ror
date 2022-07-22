module V1
  module Actions
    class GenericSerializer < ActiveModel::Serializer
      include V1::Entourages::Location

      attributes :id,
                 :uuid,
                 :status,
                 :section,
                 :title,
                 :description,
                 :image_url,
                 :event_url,
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

      def author
        return unless object.user.present?

        partner = object.user.partner

        {
          id: object.user.id,
          display_name: UserPresenter.new(user: object.user).display_name,
          avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url
        }
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
    end
  end
end
