class UserNotification < ApplicationRecord
  INSTANCES = [:neighborhood, :outing, :contribution, :solicitation]
  ACTIONS = [:show]

  belongs_to :user

  validates_presence_of :instance_id

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }

  scope :completed_by, -> (user) { where(user_id: user.id).where.not(completed_at: nil) }
  scope :skipped_by, -> (user) { where(user_id: user.id).where.not(skipped_at: nil) }
  scope :processed_by, -> (user) { UserNotificationConfiguration.completed_by(user).or(UserNotificationConfiguration.skipped_by(user)) }

  scope :active_criteria_by_user, -> (user, criteria) { active.where(user: user).where(criteria) }
  scope :processed_criteria_by_user, -> (user, criteria) { processed_by(user).where(criteria) }

  def show?
    action.to_sym == :show
  end

  def identifiant= identifiant
    self[:instance_id] = identifiant
  end
end
