module V1
  class UserSerializer < ActiveModel::Serializer
    attribute :id,           unless: :phone_only?
    attribute :display_name, unless: :phone_only?
    attribute :first_name,   unless: :phone_only?
    attribute :last_name,    unless: :phone_only?
    attribute :roles,        unless: :phone_only?
    attribute :about,        unless: :phone_only?
    attribute :avatar_url,   unless: :phone_only?
    attribute :user_type,    unless: :phone_only?
    attribute :partner,      unless: :phone_only?
    attribute :engaged,      unless: :phone_only?
    attribute :unread_count, unless: :phone_only?
    attribute :phone,        if: :phone_only?
    attribute :placeholders, if: :placeholders?
    attribute :memberships,  if: :memberships?
    attribute :conversation, if: :conversation?
    # uuid and anonymous are not confidential but right now we only need them for current_user in the clients so we don't return it in other contexts
    attribute :anonymous,           if: :default?
    attribute :uuid,                if: :default?
    attribute :feature_flags,       if: :default?
    attribute :token,               if: :default?
    attribute :email,               if: :default?
    attribute :has_password,        if: :default?
    attribute :firebase_properties, if: :default?
    attribute :goal,                if: :default?
    attribute :interests,           if: :default?

    has_one :stats,        unless: :phone_only?
    has_one :organization, serializer: ::V1::OrganizationSerializer, unless: :phone_only?
    has_one :address,      serializer: AddressSerializer, if: :default?
    has_one :address_2,    serializer: AddressSerializer, if: :default?

    def phone_only?
      scope[:phone_only] == true
    end

    def placeholders?
      me? && scope[:user].anonymous?
    end

    def memberships?
      scope[:memberships]
    end

    def conversation?
      scope[:conversation] && scope[:user]
    end

    def default?
      return false if phone_only?
      me?
    end

    def stats
      groups = object.entourage_participations.merge(JoinRequest.accepted).group(:group_type).count
      groups.default = 0

      contributions = Entourage.where(user: object).where(group_type: :action, entourage_type: :contribution).count
      ask_for_helps = Entourage.where(user: object).where(group_type: :action, entourage_type: :ask_for_help).count

      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count,
          entourage_count: object.groups.count,
          actions_count: groups['action'],
          ask_for_help_creation_count: ask_for_helps,
          contribution_creation_count: contributions,
          events_count: groups['outing'],
          good_waves_participation: groups['group'] > 0
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
      object.roles.sort_by { |r| object.community.roles.index(r) }
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

    def memberships
      return [] if object.community != 'pfp'
      groups = object.entourage_participations.merge(JoinRequest.accepted).group_by(&:group_type)
      groups.default = []
      [
        {
          type: :private_circle,
          list: groups['private_circle'].map { |e| e.attributes.slice('id', 'title', 'number_of_people') }
        },
        {
          type: :neighborhood,
          list: groups['neighborhood'].map { |e| e.attributes.slice('id', 'title', 'number_of_people') }
        }
      ]
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

    def scope
      super || {}
    end

    def me?
      scope[:user] && (object.id == scope[:user].id)
    end
  end
end
