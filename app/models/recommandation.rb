class Recommandation < ApplicationRecord
  include WithUserGoals

  INSTANCES = [:neighborhood, :outing, :poi, :resource, :webview, :contribution, :solicitation]
  ACTIONS = [:index, :show, :new, :join, :show_joined, :show_not_joined]
  FRAGMENTS = [0, 1, 2]

  validates_presence_of [:name, :instance, :action]

  alias_attribute :title, :name

  default_scope { where(status: :active) }

  scope :fragment, -> (fragment) { where(fragment: fragment) }
  scope :for_profile, -> (profile) { where(["user_goals @> ?", profile.to_json]) }

  # valides :image_url # should be ?x?
  attr_accessor :recommandation_image_id
  attr_accessor :instance_id
  attr_accessor :instance_key

  def active?
    status.to_sym == :active
  end

  def webview?
    instance.to_sym == :webview
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
end
