module V1
  class JoinRequestSerializer < ActiveModel::Serializer
    attributes :id,
               :uuid,
               :display_name,
               :role,
               :group_role,
               :community_roles,
               :status,
               :message,
               :confirmed_at,
               :participate_at,
               :photo_acceptance,
               :requested_at,
               :avatar_url,
               :partner,
               :partner_role_title

    def id
      object.user_id
    end

    def uuid
      return unless object.user

      object.user.uuid
    end

    def requested_at
      object.created_at
    end

    def display_name
      UserPresenter.new(user: object.user).display_name
    end

    def group_role
      object.role
    end

    def community_roles
      UserPresenter.new(user: object.user).public_targeting_profiles
    end

    def status
      object.simplified_status
    end

    def photo_acceptance
      object.user.photo_acceptance
    end

    def avatar_url
      UserServices::Avatar.new(user: object.user).thumbnail_url
    end

    def partner
      return unless object.user && object.user.partner_id

      V1::PartnerSerializer.new(object.user.partner, scope: {
        user: scope[:user],
        following: true
      }, root: false).as_json
    end

    def partner_role_title
      return unless object.user && object.user.partner_id

      object.user.partner_role_title.presence
    end
  end
end
