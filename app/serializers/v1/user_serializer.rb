module V1
  class UserSerializer < ActiveModel::Serializer
    attributes :id,
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
               :conversation

    has_one :organization
    has_one :stats, serializer: ActiveModel::DefaultSerializer
    has_one :address, serializer: AddressSerializer

    def filter(keys)
      keys -= [:token, :email, :has_password, :address] unless me?
      keys -= [:memberships] unless scope[:memberships]
      keys -= [:conversation] unless scope[:conversation] && scope[:user]
      keys
    end

    def stats
      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count,
          entourage_count: object.groups.count
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
      return nil unless object.partner
      V1::PartnerSerializer.new(object.partner, scope: {user: object, full: scope[:full_partner] || false}, root: false).as_json
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

    def scope
      super || {}
    end

    def me?
      scope[:user] && (object.id == scope[:user].id)
    end
  end
end
