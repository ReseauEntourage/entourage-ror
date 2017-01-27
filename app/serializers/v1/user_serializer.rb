module V1
  class UserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :display_name,
               :first_name,
               :last_name,
               :token,
               :avatar_url,
               :user_type,
               :partner

    has_one :organization
    has_one :stats

    def filter(keys)
      me? ? keys : keys - [:token, :email]
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

    def partner
      return nil unless object.default_partner
      JSON.parse(V1::PartnerSerializer.new(object.default_partner, scope: {user: object}, root: false).to_json)
    end

    def me?
      scope && (object.id == scope.id)
    end
  end
end