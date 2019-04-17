module UserService
  def self.full_name user
    join_and_capitalize(user.first_name, user.last_name)
  end

  def self.name user
    join_and_capitalize(user.first_name, user.last_name.first)
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
end
