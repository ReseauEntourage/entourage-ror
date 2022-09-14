class UserRecommandation < ApplicationRecord
  ACTIONS = [:index, :show, :new, :join]

  belongs_to :user
  belongs_to :recommandation

  scope :active, -> { where(completed_at: nil, skipped_at: nil) }

  def webview?
    instance_type.underscore.to_sym == :webview
  end

  def join?
    action.to_sym == :join
  end

  def action= action
    self[:action] = :show and return unless ACTIONS.include?(action)
    self[:action] = action
  end

  def identifiant= identifiant
    return self[:instance_url] = identifiant if webview?

    self[:instance_id] = identifiant
  end
end
