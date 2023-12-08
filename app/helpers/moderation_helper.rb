module ModerationHelper
  def moderators_for_select
    moderators = User.where("roles->>0 = 'moderator'").map do |moderator|
      ["#{moderator.full_name} (#{moderator.email})", moderator.id]
    end.sort_by { |moderator| moderator.first.downcase }
  end

  def moderation_area_filters
    departement_filters = ModerationArea.only_departements.map do |departement|
      [departement, {country_eq: 'FR', postal_code_start: departement}]
    end.to_h

    {
      "Partout" => {},
    }.merge(departement_filters).merge({
      "Hors zone" => {
        postal_code_not_start_all: ModerationArea.only_departements
      },
    })
  end
end
