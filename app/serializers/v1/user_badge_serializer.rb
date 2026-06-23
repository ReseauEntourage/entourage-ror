module V1
  class UserBadgeSerializer < ActiveModel::Serializer
    attributes :name,
               :active,
               :awarded_at,
               :metadata

    def name
      object.badge_tag
    end
  end
end
