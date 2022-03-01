module UserService
  DEFAULT_DISTANCE = 10

  def self.full_name user
    join_and_capitalize(user.first_name, user.last_name)
  end

  def self.join_and_capitalize first, last
    [first, last].map(&:presence).compact.map(&:capitalize).join(' ').squish
  end

  def self.sync_roles user
    return unless user.community == :entourage
    roles = user.roles - [:ambassador]
    roles.push :ambassador if user.targeting_profile == 'ambassador'
    user.roles = roles.sort_by { |r| user.community.roles.index(r) }
  end

  def self.external_uuid user
    if user.anonymous?
      "1_anonymous_#{user.uuid}"
    else
      user.id.to_s
    end
  end

  def self.travel_distance user:, forced_distance: nil
    [(forced_distance&.to_f || user.travel_distance || DEFAULT_DISTANCE), 40].min
  end

  def self.firebase_properties user
    # Names should contain 1 to 24 alphanumeric characters or underscores
    # and must start with an alphabetic character.
    # The "firebase_", "google_", and "ga_" prefixes are reserved.
    #
    # Values can be up to 36 characters long.
    # Setting the value to nil removes the user property.
    #
    # As much as possible, we must always return the same property names
    # so that we overwrite the previous values when the user changes.

    departments = []
    postal_codes = []

    user.addresses.each do |address|
      postal_code, department =
        if address.postal_code.nil?
          [:not_set, :not_set]
        elsif address.country != 'FR'
          [:not_FR,  :not_FR]
        elsif address.postal_code.last == 'X'
          [:not_set,
           address.postal_code.first(2)]
        else
          [address.postal_code,
           address.postal_code.first(2)]
        end

      departments << department
      postal_codes << postal_code
    end

    [departments, postal_codes].each do |list|
      list.uniq!
      list.delete :not_set if (list - [:not_set]).any?
      list.delete :not_FR  if (list - [:not_FR]).any?
      list.push :not_set if list.empty?
      list.sort!
    end

    goal = user.goal.presence || :no_set

    interests = (user.interest_list || []).sort.uniq
    interests = [:none] if interests.empty?

    {
      ActionZoneDep: departments.join(','),
      ActionZoneCP:  postal_codes.join(','),
      Goal: goal.to_s,
      Interests: interests.join(',')
    }
  end
end
