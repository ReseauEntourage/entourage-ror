class InappNotification < ApplicationRecord
  INSTANCES = [:neighborhood, :outing, :contribution, :solicitation, :user, :neighborhood_post, :outing_post]

  belongs_to :user # user that is notified
  belongs_to :sender, class_name: :User # user that created the notification
  belongs_to :post

  validates_presence_of :instance, :instance_id
  # validates_inclusion_of :instance, in: INSTANCES

  default_scope { order(created_at: :desc) }

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }
  scope :displayed, -> { where.not(displayed_at: nil) }
  scope :not_displayed, -> { where(displayed_at: nil) }

  scope :completed_by, -> (user) { where(user_id: user.id).where.not(completed_at: nil) }
  scope :skipped_by, -> (user) { where(user_id: user.id).where.not(skipped_at: nil) }
  scope :processed_by, -> (user) { InappNotificationConfiguration.completed_by(user).or(InappNotificationConfiguration.skipped_by(user)) }

  scope :active_criteria_by_user, -> (user, criteria) { active.where(user: user).where(criteria) }
  scope :processed_criteria_by_user, -> (user, criteria) { processed_by(user).where(criteria) }


  def record
    return unless instance
    return post if post?

    instance.to_s.classify.constantize.unscoped.find_by_id(instance_id)
  rescue NameError
    nil
  end

  def post?
    return unless instance

    [:neighborhood_post, :outing_post].include?(instance.to_sym)
  end
end
