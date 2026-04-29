class EngagementLevel < ApplicationRecord
  self.primary_key = :user_id

  belongs_to :user

  def readonly?
    true
  end
end
