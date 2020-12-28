require 'experimental'
class Experimental::PendingRequestReminder < ApplicationRecord
  belongs_to :user

  RECENCY_DEFINITION = 1.week

  scope :recent, -> { where("created_at >= ?", RECENCY_DEFINITION.ago) }
end
