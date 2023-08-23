module V1
  class ChatMessageSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid_v2,
               :content,
               :user,
               :created_at,
               :message_type,
               :status

    attribute :metadata, if: :metadata?

    def metadata?
      object.message_type.in?(['outing', 'status_update', 'share'])
    end

    def user
      partner = object.user.partner

      {
        id: object.user_id,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        display_name: display_name,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: {}, root: false).as_json,
        partner_role_title: object.user.partner_role_title.presence,
        roles: UserPresenter.new(user: object.user).public_targeting_profiles
      }
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def metadata
      object.metadata.except(:$id)
    end
  end
end
