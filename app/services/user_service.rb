module UserService
  def self.full_name user
    join_name_parts(user.first_name, user.last_name)
  end

  def self.name user
    join_name_parts(user.first_name, user.last_name.first)
  end

  def self.join_name_parts first, last
    [first, last].map(&:presence).compact.join(' ').squish
  end
end
