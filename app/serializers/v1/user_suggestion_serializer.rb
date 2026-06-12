module V1
  class UserSuggestionSerializer < ActiveModel::Serializer
    attributes :id,
               :suggestion_type,
               :suggested_action,
               :reason,
               :reason_type,
               :expires_at,
               :suggested_user_info,
               :suggested_entourage_info

    def suggested_user_info
      return nil unless object.suggested_user.present?

      u = object.suggested_user
      address = Address.where(user_id: u.id, position: 1).first

      {
        id: u.id,
        uuid: u.uuid,
        first_name: u.first_name,
        avatar_url: u.avatar_url,
        postal_code: address&.postal_code
      }
    end

    def suggested_entourage_info
      return nil unless object.suggested_entourage.present?

      e = object.suggested_entourage

      {
        id: e.id,
        uuid: e.uuid,
        title: e.title,
        group_type: e.group_type,
        display_category: e.display_category,
        metadata: e.metadata
      }
    end
  end
end
