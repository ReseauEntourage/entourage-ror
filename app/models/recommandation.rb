class Recommandation < ApplicationRecord
  include WithAreas
  include WithUserGoals

  validates_presence_of [:name, :instance, :action]

  alias_attribute :title, :name

  default_scope { where(status: :active) }

  # valides :image_url # should be ?x?
  attr_accessor :recommandation_image_id
  attr_accessor :instance_id
  attr_accessor :instance_key

  def active?
    status.to_sym == :active
  end

  def show?
    action.to_sym == :show
  end

  def image_url
    return unless self['image_url'].present?

    RecommandationImage.image_url_for self['image_url']
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
