module V1
  class UserSerializer < ActiveModel::Serializer
    attributes :id,
               :phone,
               :email,
               :display_name,
               :first_name,
               :last_name,
               :roles,
               :about,
               :token,
               :avatar_url,
               :user_type,
               :partner,
               :memberships,
               :has_password,
               :conversation,
               :anonymous,
               :uuid,
               :goal,
               :interests,
               :firebase_properties,
               :placeholders,
               :feature_flags,
               :engaged,
               :unread_count

    has_one :organization
    has_one :stats, serializer: ActiveModel::DefaultSerializer
    has_one :address, serializer: AddressSerializer
    has_one :address_2, serializer: AddressSerializer

    def filter(keys)
      if scope[:phone_only] == true
        return [:phone]
      else
        keys -= [:phone]
      end

      keys -= [:token, :email, :has_password, :address, :address_2, :firebase_properties, :goal, :interests] unless me?

      # uuid and anonymous are not confidential but right now we only need
      # them for current_user in the clients so we don't return it in other
      # contexts
      keys -= [:anonymous, :uuid, :feature_flags] unless me?

      # FIXME: see comment above the definition of placeholder
      keys -= [:placeholders] unless me? && scope[:user].anonymous?

      keys -= [:memberships] unless scope[:memberships]
      keys -= [:conversation] unless scope[:conversation] && scope[:user]
      keys
    end

    def stats
      groups = object.entourage_participations.merge(JoinRequest.accepted).group(:group_type).count
      groups.default = 0

      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count,
          entourage_count: object.groups.count,
          actions_count: groups['action'],
          ask_for_help_creation_count: object.ask_for_help_creation_count,
          contribution_creation_count: object.contribution_creation_count,
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
