module V1
  class UserSerializer < ActiveModel::Serializer
    attribute :id
    attribute :lang
    attribute :display_name
    attribute :first_name
    attribute :last_name
    attribute :roles
    attribute :about
    attribute :availability
    attribute :avatar_url
    attribute :user_type
    attribute :partner
    attribute :engaged
    attribute :unread_count
    attribute :permissions
    attribute :interests
    attribute :involvements
    attribute :concerns
    attribute :placeholders, if: :placeholders?
    attribute :memberships,  if: :memberships?
    attribute :conversation, if: :conversation?
    # uuid and anonymous are not confidential but right now we only need them for current_user in the clients so we don't return it in other contexts
    attribute :anonymous,           if: :me?
    attribute :uuid,                if: :me?
    attribute :feature_flags,       if: :me?
    attribute :token,               if: :me?
    attribute :email,               if: :me?
    attribute :has_password,        if: :me?
    attribute :firebase_properties, if: :me?
    attribute :goal,                if: :me?
    attribute :phone,               if: :me?
    attribute :travel_distance,     if: :me?
    attribute :birthday,            if: :me?
    attribute :created_at

    has_one :stats
    has_one :address, serializer: AddressSerializer
    has_one :address_2, serializer: AddressSerializer

    def placeholders?
      me? && scope[:user].anonymous?
    end

    def memberships?
      scope[:memberships]
    end

    def conversation?
      scope[:conversation] && scope[:user]
    end

    def stats
      groups = object.entourage_participations.merge(JoinRequest.accepted).group(:group_type).count
      groups.default = 0

      {
          tour_count: 0,
          encounter_count: 0,
          entourage_count: object.groups.count,
          actions_count: groups['action'],
          ask_for_help_creation_count: object.ask_for_help_creation_count,
          contribution_creation_count: object.contribution_creation_count,
          events_count: groups['outing'],
          outings_count: groups['outing'],
          neighborhoods_count: object.neighborhood_memberships.count,
          good_waves_participation: false
      }
    end

    def avatar_url
      UserServices::Avatar.new(user: object).thumbnail_url
    end

    def display_name
      UserPresenter.new(user: object).display_name
    end

    def last_name
      if me?
        object.last_name
      else
        object.last_name.presence&.first
      end
    end

    def roles
      UserPresenter.new(user: object).public_targeting_profiles
    end

    def partner
      return unless object.partner

      partner = V1::PartnerSerializer.new(object.partner, scope: { full: scope[:full_partner] || false }, root: false).as_json
      partner[:user_role_title] = object.partner_role_title.presence
      partner
    end

    def has_password
      object.has_password?
    end

    # @deprecated
    def memberships
      return []
    end

    def conversation
      {
        uuid: ConversationService.uuid_for_participants([scope[:user].id, object.id], validated: false)
      }
    end

    def anonymous
      object.anonymous?
    end

    def uuid
      UserService.external_uuid(object)
    end

    def firebase_properties
      UserService.firebase_properties(object)
    end

    def interests
      # we use "Tag.interest_list &" to force ordering
      Tag.interest_list & object.interest_names
    end

    def involvements
      # we use "Tag.involvement_list &" to force ordering
      Tag.involvement_list & object.involvement_names
    end

    def concerns
      # we use "Tag.concern_list &" to force ordering
      Tag.concern_list & object.concern_names
    end

    # FIXME: the placeholders attribute is a hack. It indicates to the clients
    # that if there is a value in local storage for the attributes listed,
    # the local value should be used instead of the one provided by the server.
    # This allows to have some persistence of the attributes of anonymous users.
    def placeholders
      [:firebase_properties, :address, :address_2]
    end

    def feature_flags
      {
        organization_admin: (object.partner_id.present? && User.where(partner_id: object.partner_id, partner_admin: true).exists?)
      }
    end

    def engaged
      object.engaged?
    end

    def unread_count
      UserServices::UnreadMessages.new(user: object).number_of_unread_messages
    end

    def permissions
      {
        outing: {
          creation: object.partner.present? || object.admin? || object.ambassador?
        }
      }
    end

    def scope
      super || {}
    end

    def me?
      scope[:user] && (object.id == scope[:user].id)
    end
  end
end
