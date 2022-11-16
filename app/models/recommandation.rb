class Recommandation < ApplicationRecord
  include WithUserGoals

  STATUS = %w[active deleted].freeze

  INSTANCES = [:neighborhood, :outing, :poi, :resource, :webview, :contribution, :solicitation, :user]
  ACTIONS = [:index, :show, :create, :join, :show_joined, :show_not_joined]
  FRAGMENTS = [0, 1, 2]
  FRAGMENT_RESOURCES = 0
  FRAGMENT_GROUPS = 1
  FRAGMENT_OUTINGS = 1
  FRAGMENT_ACTIONS = 2

  validates_presence_of [:name, :instance, :action]
  validates :status, inclusion: STATUS

  alias_attribute :title, :name

  default_scope { where(status: :active) }

  scope :fragment, -> (fragment) { where(fragment: fragment) }
  scope :for_profile, -> (profile) {
    order = profile&.to_sym == :offer_help ? :position_offer_help : :position_ask_for_help

    where(["user_goals @> ?", profile.to_json]).order(order)
  }
  scope :recommandable_for, -> (user) {
    where.not(id: UserRecommandation.completed_by(user).pluck(:recommandation_id))
  }
  scope :order_by_skipped_at, -> (user) {
    joins(sanitize_sql_array([
      %(
        left outer join user_recommandations
        on recommandations.id = user_recommandations.recommandation_id
        and user_recommandations.user_id = :user_id
      ),
      { user_id: user.id }
    ]))
    .order("user_recommandations.skipped_at is null desc, user_recommandations.skipped_at asc")
  }

  # valides :image_url # should be ?x?
  attr_accessor :recommandation_image_id
  attr_accessor :instance_id
  attr_accessor :instance_key

  class << self
    def recommandable_for_user_and_fragment user, fragment
      profile = (user.is_ask_for_help? ? :ask_for_help : :offer_help)

      Recommandation
        .fragment(fragment)
        .for_profile(profile)
        .recommandable_for(user)
        .order_by_skipped_at(user)
    end
  end

  STATUS.each do |status|
    scope status, -> { where(status: status) }

    define_method("#{status}?") do
      self.status == status
    end
  end

  def self.preferred_instance_for_user_and_fragment user, fragment
    return if fragment == Recommandation::FRAGMENT_RESOURCES

    return Outing if fragment == FRAGMENT_OUTINGS
    return Contribution if user.is_ask_for_help?

    Solicitation
  end

  def webview?
    instance.to_sym == :webview
  end

  def resource?
    instance.to_sym == :resource
  end

  def show?
    action.to_sym == :show
  end

  def showable?
    [:show, :show_joined, :show_not_joined].include?(action.to_sym)
  end

  def image_url
    return unless self['image_url'].present?

    RecommandationImage.image_url_for self['image_url']
  end

  def position_for_profile profile
    return position_offer_help if profile&.to_sym == :offer_help
    return position_ask_for_help if profile&.to_sym == :ask_for_help

    nil
  end

  def recommandation_image_id= recommandation_image_id
    if recommandation_image = RecommandationImage.find_by_id(recommandation_image_id)
      self.image_url = recommandation_image[:image_url]
    else
      remove_recommandation_image_id!
    end
  end

  def remove_recommandation_image_id!
    self.image_url = nil
  end

  def matches criteria
    # @caution instruction order matters
    return matches_show_webview(criteria) if show? && webview?
    return matches_show(criteria) if show?
    return matches_specific_show(criteria) if showable?

    matches_no_show(criteria)
  end

  protected

  def matches_show_webview criteria
    criteria.include?({ "action" => "show", "instance" => "webview", "instance_id" => nil, "instance_url" => argument_value })
  end

  def matches_show criteria
    criteria.include?({ "action" => "show", "instance" => instance, "instance_id" => argument_value.to_i, "instance_url" => nil })
  end

  def matches_specific_show criteria
    criteria.any? do |criterion|
      criterion["action"] == "show" && criterion["instance"] == instance
    end
  end

  def matches_no_show criteria
    criteria.any? do |criterion|
      criterion["action"] == action && criterion["instance"] == instance
    end
  end
end
