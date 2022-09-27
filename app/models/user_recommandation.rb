class UserRecommandation < ApplicationRecord
  ACTIONS = [:index, :show, :create, :join]

  belongs_to :user
  belongs_to :recommandation

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }

  scope :completed_by, -> (user) { where(user_id: user.id).where.not(completed_at: nil) }
  scope :skipped_by, -> (user) { where(user_id: user.id).where.not(skipped_at: nil) }
  scope :processed_by, -> (user) { UserRecommandation.completed_by(user).or(UserRecommandation.skipped_by(user)) }

  scope :to_be_congratulated, -> { where.not(completed_at: nil).where(congrats_at: nil) }
  scope :for_instance, -> (instance) { where(instance_type: instance.to_s.classify) }

  def webview?
    instance_type.underscore.to_sym == :webview
  end

  def join?
    action.to_sym == :join
  end

  def action= action
    self[:action] = :show and return unless ACTIONS.include?(action.to_sym)
    self[:action] = action
  end

  def identifiant= identifiant
    return self[:instance_url] = identifiant if webview?

    self[:instance_id] = identifiant
  end
end
