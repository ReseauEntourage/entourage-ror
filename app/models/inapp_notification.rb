class InappNotification < ApplicationRecord
  INSTANCES = [:neighborhood, :outing, :contribution, :solicitation, :user, :neighborhood_post, :outing_post, :resource]

  belongs_to :user # user that is notified
  belongs_to :sender, class_name: :User, required: false # user that created the notification
  belongs_to :post, class_name: :ChatMessage, required: false

  default_scope { order(created_at: :desc) }

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }
  scope :displayed, -> { where.not(displayed_at: nil) }
  scope :not_displayed, -> { where(displayed_at: nil) }

  scope :completed_by, -> (user) { where(user_id: user.id).where.not(completed_at: nil) }
  scope :skipped_by, -> (user) { where(user_id: user.id).where.not(skipped_at: nil) }
  scope :processed_by, -> (user) { InappNotificationConfiguration.completed_by(user).or(InappNotificationConfiguration.skipped_by(user)) }

  scope :active_criteria_by_user, -> (user, criteria) { active.where(user: user).where(criteria) }
  scope :processed_criteria_by_user, -> (user, criteria) { processed_by(user).where(criteria) }

  scope :with_context, -> (context) {
    return unless context.present?
    return if context.to_sym == :all

    where(context: context)
  }

  def instance= instance
    self.instance_baseclass = instance.to_s.camelize
    self.instance_baseclass = "ChatMessage" if [:neighborhood_post, :outing_post].include?(instance&.to_sym)
    self.instance_baseclass = "Entourage" if [:contribution, :solicitation, :outing].include?(instance&.to_sym)

    super(instance)
  end

  def record
    return unless instance
    return post if post?

    instance.to_s.classify.constantize.unscoped.find_by_id(instance_id)
  rescue NameError
    nil
  end

  def post?
    return false unless instance

    [:neighborhood_post, :outing_post].include?(instance.to_sym)
  end

  def chat_message_on_create?
    return false unless context

    :chat_message_on_create == context.to_sym
  end

  def join_request?
    return false unless context

    [:join_request_on_create, :join_request_on_update].include?(context.to_sym)
  end
end
