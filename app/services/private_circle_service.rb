module PrivateCircleService
  def self.generate_title private_circle
    first_name = private_circle.metadata.symbolize_keys[:visited_user_first_name]
    if "aehiouy".include?(first_name.first.downcase)
      "Les amis d'#{first_name}"
    else
      "Les amis de #{first_name}"
    end
  end
end
