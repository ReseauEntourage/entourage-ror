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
end
