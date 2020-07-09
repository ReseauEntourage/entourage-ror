class UserGoalPresenter
  attr_reader :slug

  def initialize slug, community:
    @slug = slug
    @community = community
  end

  def name
    I18n.t "community.#{@community.slug}.goals.#{slug}"
  end

  def self.all_slugs community
    community.goals + [:goal_not_known]
  end

  def self.all community
    all_slugs(community).map { |slug| new(slug, community: community) }
  end
end
