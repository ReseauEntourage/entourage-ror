class Resource < ApplicationRecord
  CATEGORIES  = [:all, :understand, :act, :inspire]

  has_many :users_resources
  has_many :users, -> { where(watched: true) }, through: :users_resources, source: :user

  def views
    users_resources.watched.count
  end
end
