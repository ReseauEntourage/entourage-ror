module NeighborhoodServices
  class Finder
    def self.search user:, q: nil
      Neighborhood.like(q).not_joined_by(user)
        .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
        .order_by_interests_matching(user.interest_list)
        .order_by_activity
        .order_by_distance_from(user.latitude, user.longitude)
    end
  end
end
