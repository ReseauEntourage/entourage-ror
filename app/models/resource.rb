class Resource < ApplicationRecord
  include Recommandable
  include Deeplinkable
  include Translatable

  CATEGORIES  = [:understand, :act, :inspire]

  # STATUSES = [:active, :deleted]
  default_scope { where(status: :active) }

  has_many :users_resources
  has_many :users_resources_watched, -> { where(watched: true) }, class_name: :UsersResource
  has_many :users, through: :users_resources_watched, source: :user

  scope :ordered, -> { order(:position, :id) }

  # valides :image_url # should be ?x?
  attr_accessor :resource_image_id

  def image_url
    return unless self['image_url'].present?

    ResourceImage.image_url_for self['image_url']
  end

  def image_url_with_size size = :medium
    return unless self['image_url'].present?

    ResourceImage.image_url_for_with_size(self['image_url'], size)
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
