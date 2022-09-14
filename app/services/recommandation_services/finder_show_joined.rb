module RecommandationServices
  class FinderShowJoined
    class << self
      def find_identifiant user, recommandation
        method = "find_#{recommandation.instance}".to_sym

        return unless methods.include?(method)
        return unless instance = send(method, user)

        instance.id
      end

      def find_neighborhood user
        Neighborhood.joined_by(user)
          .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
          .order_by_distance_from(user.latitude, user.longitude)
          .first
      end

      def find_outing user
        Outing.joined_by(user)
          .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
          .order_by_distance_from(user.latitude, user.longitude)
          .first
      end
    end
  end
end
