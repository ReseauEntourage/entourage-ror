class LoginHistory < ApplicationRecord
  belongs_to :user

  validates :user_id, :connected_at, presence: true
  validate :unique_login_by_hour

  def unique_login_by_hour
    if self.connected_at && LoginHistory.where(user_id: self.user_id)
                              .where("date_trunc('hour', connected_at) = ?", self.connected_at.utc.strftime('%Y-%m-%d %H:00:00'))
                              .count>0
      errors.add(:text, 'already exist for this hour')
    end
  end
end
