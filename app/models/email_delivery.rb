class EmailDelivery < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user_id, :campaign, :sent_at
  validates_numericality_of :user_id

  before_validation do
    self.sent_at ||= Time.now
  end
end
