module CoordinatesScopable
  extend ActiveSupport::Concern

  CITIES = {
    lille: { field: :postal_code, in: ['59000', '59130', '59160', '59260', '59350', '59777', '59800'] },
    lyon: { field: :postal_code, in: ('69000'..'69009').to_a },
    marseille: { field: :postal_code, in: ('13000'..'13016').to_a },
    paris: { field: :departement, in: '75' },
    rennes: { field: :postal_code, in: ['35000', '35200', '35700', '35740', '35760', '35760', '35510', '35132', '35650', '35590', '35520', '35135', '35830', '35235', '35770'] },
  }

  included do
    scope :inside_perimeter, -> (latitude, longitude, travel_distance) {
      if latitude && longitude
        where(Arel.sql("#{PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)} < #{travel_distance}"))
      end
    }
    scope :inside_user_perimeter, -> (user) {
      return none unless user.departement.present?

      inside_perimeter(user.latitude, user.longitude, user.travel_distance).or(
        with_departement(user.departement)
      )
    }
    scope :order_by_distance_from, -> (latitude, longitude) {
      if latitude && longitude
        order(Arel.sql(PostgisHelper.distance_from(latitude, longitude, table_name.to_sym)))
      end
    }
    scope :with_departement, -> (departement) {
      return unless has_attribute?(:zone)

      where(zone: :departement).where(
        'postal_code is not null and left(postal_code, 2) = ?', departement
      )
    }
    scope :with_zone, -> (zone) {
      return unless has_attribute?(:zone)
      return unless zone.present?
      return unless [:ville, :departement, :no_zone].include?(zone)

      return where(zone: nil) if zone == :no_zone

      where(zone: zone)
    }
    scope :order_by_paris_for_user, -> (user) {
      return unless user.paris?

      if has_attribute?(:zone)
        order(Arel.sql("case when zone = 'ville' and left(postal_code, 2) = '75' then 0 else 1 end"))
      else
        order(Arel.sql("case when left(postal_code, 2) = '75' then 0 else 1 end"))
      end
    }
    scope :order_by_city_for_user, -> (user, city) {
      return unless is_in_city?(user, city)

      cities = in_city(city).map { |a| ApplicationRecord.connection.quote(a) }.join(',')

      if has_attribute?(:zone)
        order(Arel.sql("case when zone = 'ville' and postal_code in (#{cities}) then 0 else 1 end"))
      else
        order(Arel.sql("case when postal_code in (#{cities}) then 0 else 1 end"))
      end
    }
    scope :order_by_zone, -> {
      return unless has_attribute?(:zone)

      order(Arel.sql(%(
        case when zone = 'ville' then 0
             when zone = 'departement' then 1
        else 2 end
      )))
    }

    scope :closests_to_by_zone, -> (user) {
      inside_user_perimeter(user)
        .unscope(:order)
        .order_by_paris_for_user(user)
        .order_by_city_for_user(user, :rennes)
        .order_by_city_for_user(user, :lille)
        .order_by_city_for_user(user, :lyon)
        .order_by_city_for_user(user, :marseille)
        .order_by_zone
        .order_by_distance_from(user.latitude, user.longitude)
    }
  end

  private

  class_methods do
    def is_in_city? user, city
      return false unless values = CITIES.dig(city, :in)
      return false unless field = user.send(CITIES[city][:field])

      values.include?(field)
    end

    def in_city city
      CITIES[city][:in]
    end
  end
end
