module V1
  class NeighborhoodOutingSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid,
               :title,
               :description,
               :share_url,
               :image_url,
               :event_url,
               :author,
               :online,
               :metadata,
               :interests,
               :neighborhood_ids

    def uuid
      object.uuid_v2
    end

    def author
      return unless object.user.present?

      partner = object.user.partner

      {
        id: object.user.id,
        display_name: UserPresenter.new(user: object.user).display_name,
        avatar_url: UserServices::Avatar.new(user: object.user).thumbnail_url,
        partner: partner.nil? ? nil : V1::PartnerSerializer.new(partner, scope: { minimal: true }, root: false).as_json,
        partner_role_title: object.user.partner_role_title.presence
      }
    end

    def metadata
      object.metadata_with_image_paths.except(:$id)
    end

    def interests
      # we use "Tag.interest_list &" to force ordering
      Tag.interest_list & object.interest_list
    end
  end
end
