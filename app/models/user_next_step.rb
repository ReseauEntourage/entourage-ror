class UserNextStep < ApplicationRecord
  belongs_to :user
  belongs_to :next_step_suggestion

  STATUSES = %w[active completed dismissed].freeze
  validates :status, inclusion: { in: STATUSES }

  scope :active_status, -> { where(status: 'active') }
  scope :recent_dismissals, -> { where(status: 'dismissed').where('dismissed_at > ?', 30.days.ago) }

  def complete!
    update!(status: 'completed', acted_at: Time.zone.now)
  end

  def dismiss!
    update!(status: 'dismissed', dismissed_at: Time.zone.now)
  end

  def expired?
    expires_at.present? && expires_at < Time.zone.now
  end
end
