module V0
  class UserSerializer < ActiveModel::Serializer
    attributes :id,
               :email,
               :first_name,
               :last_name,
               :token

    has_one :organization
    has_one :stats

    def stats
      {
          tour_count: object.tours.count,
          encounter_count: object.encounters.count
      }
    end
  end
end
