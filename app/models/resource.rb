class Resource < ApplicationRecord
  CATEGORIES  = [:all, :understand, :act, :inspire]

  has_many :users_resources

  def views
    users_resources.displayed.count
  end
end
