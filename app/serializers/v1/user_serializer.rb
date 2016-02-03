module V1
  class UserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :first_name,
               :last_name,
               :token,
               :avatar_url

    has_one :organization
    has_one :stats

    def stats
      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count
      }
    end

    def avatar_url
      UserServices::Avatar.new(user: object).thumbnail_url
    end
  end
end