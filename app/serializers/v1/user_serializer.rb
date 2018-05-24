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
               :has_password

    has_one :organization
    has_one :stats, serializer: ActiveModel::DefaultSerializer

    def filter(keys)
      keys -= [:token, :email, :has_password] unless me?
      keys -= [:memberships] unless scope[:memberships]
      keys
    end

    def stats
      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count,
          entourage_count: object.entourages.count
      }
    end

    def avatar_url
      UserServices::Avatar.new(user: object).thumbnail_url
    end

    def display_name
      UserPresenter.new(user: object).display_name
    end

    def roles
      object.roles.sort_by { |r| object.community.roles.index(r) }
    end

    def partner
      return nil unless object.default_partner
      JSON.parse(V1::PartnerSerializer.new(object.default_partner, scope: {user: object, full: scope[:full_partner] || false}, root: false).to_json)
    end

    def has_password
      object.has_password?
    end

    def memberships
      return [] if object.community != 'pfp'
      [
        {
          type: :private_circle,
          list: object.entourages.map { |e| e.attributes.slice('id', 'title', 'number_of_people') }
        },
        {
          type: :neighborhood,
          list: []
        }
      ]
    end

    def scope
      super || {}
    end

    def me?
      scope[:user] && (object.id == scope[:user].id)
    end
  end
end