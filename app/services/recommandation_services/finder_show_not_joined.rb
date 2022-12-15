module RecommandationServices
  class FinderShowNotJoined
    class << self
      def find_identifiant user, recommandation
        klass = Object.const_get(recommandation.instance.to_s.classify)

        return unless klass.respond_to? :not_joined_by
        return unless klass.respond_to? :inside_perimeter
        return unless klass.respond_to? :order_by_distance_from

        klass.not_joined_by(user)
          .recommandable
          .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
          .order_by_distance_from(user.latitude, user.longitude)
          .pluck(:id)
          .first
      end
    end
  end
end
