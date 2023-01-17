module CoordinatesScopable
  extend ActiveSupport::Concern

  included do
    scope :inside_perimeter, -> (latitude, longitude, travel_distance) {
      if latitude && longitude
        where("#{PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)} < ?", travel_distance)
      end
    }
    scope :inside_user_perimeter, -> (user) {
      inside_perimeter(user.latitude, user.longitude, user.travel_distance).or(
        with_departement(user.departement)
      )
    }
    scope :order_by_distance_from, -> (latitude, longitude) {
      if latitude && longitude
        order(PostgisHelper.distance_from(latitude, longitude, table_name.to_sym))
      end
    }
    scope :with_departement, -> (departement) {
      return unless has_attribute?(:is_departement)

      where(is_departement: true).where(
        "postal_code is not null and left(postal_code, 2) = ?", departement
      )
    }
    scope :order_by_not_departement, -> {
      return unless has_attribute?(:is_departement)

      order("case when is_departement then 1 else 0 end")
    }

    scope :closests_to, -> (user) {
      inside_user_perimeter(user)
        .unscope(:order)
        .order_by_not_departement
        .order_by_distance_from(user.latitude, user.longitude)
    }
  end
end
