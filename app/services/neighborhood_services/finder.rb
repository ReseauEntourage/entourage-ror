module NeighborhoodServices
  class Finder
    def self.search user, q
      neighborhoods = Neighborhood.order_by_distance_from(user.latitude, user.longitude)
      neighborhoods = neighborhoods.like(q) if q.present?

      neighborhoods
    end
  end
end
