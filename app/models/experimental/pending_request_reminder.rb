class Experimental::PendingRequestReminder < ActiveRecord::Base
  belongs_to :user

  RECENCY_DEFINITION = 1.week

  scope :recent, -> { where("created_at >= ?", RECENCY_DEFINITION.ago) }
end
