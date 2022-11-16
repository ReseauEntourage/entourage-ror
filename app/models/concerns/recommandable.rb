module Recommandable
  extend ActiveSupport::Concern

  included do
    scope :closests_recommandable_to, -> (user) {
      visited_instances = UserRecommandation.select(:instance_id).visit_processed_by(user).where(instance: self.name.underscore)

      self
        .not_joined_by(user)
        .where.not(id: visited_instances)
        .inside_perimeter(user.latitude, user.longitude, user.travel_distance)
        .order_by_distance_from(user.latitude, user.longitude)
    }
  end
end
