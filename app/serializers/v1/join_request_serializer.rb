module V1
  class JoinRequestSerializer < ActiveModel::Serializer
    attributes :id,
               :display_name,
               :role,
               :group_role,
               :community_roles,
               :status,
               :message,
               :requested_at,
               :avatar_url,
               :partner,
               :partner_role_title

    def id
      object.user.id
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
      user = object.user
      user.roles.sort_by { |r| user.community.roles.index(r) }
    end

    def status
      object.persisted? ? object.status : "not requested"
    end

    def avatar_url
      UserServices::Avatar.new(user: object.user).thumbnail_url
    end

    def partner
      return nil unless object.user.partner
      V1::PartnerSerializer.new(object.user.partner, scope: {user: object.user}, root: false).as_json
    end

    def partner_role_title
      user = object.user
      user.partner_role_title.presence if user.partner_id
    end
  end
end
