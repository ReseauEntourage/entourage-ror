module ModerationHelper
  def moderators_for_select
    moderators = User.where("roles->>0 = 'moderator'").map do |moderator|
      ["#{moderator.full_name} (#{moderator.email})", moderator.id]
    end
  end
end
