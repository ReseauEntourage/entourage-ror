class Resource < ApplicationRecord
  CATEGORIES  = [:understand, :act, :inspire]

  # STATUSES = [:active, :deleted]
  default_scope { where(status: :active) }

  has_many :users_resources
  has_many :users, -> { where(watched: true) }, through: :users_resources, source: :user

  scope :ordered, -> { order(:position, :id) }

  # valides :image_url # should be ?x?
  attr_accessor :resource_image_id

  def views
    users_resources.watched.count
  end

  def image_url
    return unless self['image_url'].present?

    ResourceImage.image_url_for self['image_url']
  end

  def resource_image_id= resource_image_id
    if resource_image = ResourceImage.find_by_id(resource_image_id)
      self.image_url = resource_image[:image_url]
    else
      remove_resource_image_id!
    end
  end

  def remove_resource_image_id!
    self.image_url = nil
  end
end
