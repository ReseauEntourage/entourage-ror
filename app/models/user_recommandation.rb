class UserRecommandation < ApplicationRecord
  ACTIONS = [:index, :show, :create, :join]

  belongs_to :user
  belongs_to :recommandation

  validates_presence_of :instance_id, if: Proc.new { |object| object.show? && !object.webview? }
  validates_presence_of :instance_url, if: Proc.new { |object| object.show? && object.webview? }

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }

  scope :orphan, -> { where(recommandation_id: nil) }

  scope :completed_by, -> (user) { where(user_id: user.id).where.not(completed_at: nil) }
  scope :skipped_by, -> (user) { where(user_id: user.id).where.not(skipped_at: nil) }
  scope :processed_by, -> (user) { UserRecommandation.completed_by(user).or(UserRecommandation.skipped_by(user)) }

  scope :to_be_congratulated, -> { where.not(completed_at: nil).where(congrats_at: nil).where.not(recommandation_id: nil) }

  scope :active_criteria_by_user, -> (user, criteria) { active.where(user: user).where(criteria) }
  scope :processed_criteria_by_user, -> (user, criteria) { processed_by(user).where(criteria) }

  def webview?
    instance.to_sym == :webview
  end

  def join?
    action.to_sym == :join
  end

  def show?
    action.to_sym == :show
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
