module V1
  class ChatMessageSerializer < ActiveModel::Serializer
    attributes :id,
               :content,
               :user,
               :created_at,
               :message_type

    attribute :metadata, if: :metadata?

    attribute :parent_id, if: :neighborhood?
    attribute :has_children, if: :neighborhood?
    attribute :children_count, if: :neighborhood?
    attribute :image_url, if: :neighborhood?

    def metadata?
      object.message_type.in?(['outing', 'status_update', 'share'])
    end

    def neighborhood?
      object.messageable_type.in?(['Neighborhood'])
    end

    def user
      {
        id: chat_user.id,
        avatar_url: UserServices::Avatar.new(user: chat_user).thumbnail_url,
        display_name: display_name,
        partner: chat_user.partner.nil? ? nil : V1::PartnerSerializer.new(chat_user.partner, scope: {}, root: false).as_json
      }
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def chat_user
      object.user
    end

    def metadata
      object.metadata.except(:$id)
    end

    def has_children
      object.has_children?
    end

    def children_count
      object.children.count
    end

    def image_url
      if object.parent_id.nil?
        "https://picsum.photos/200/300"
      end
    end
  end
end
