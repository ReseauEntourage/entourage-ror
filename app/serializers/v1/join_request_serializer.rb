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
      object.user_id
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
      user.roles.sort_by { |r| user.community.roles.index(r) }.map do |role|
        I18n.t("community.entourage.roles.#{role}")
      end
    end

    def status
      object.simplified_status
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
