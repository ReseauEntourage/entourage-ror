class UserSuggestion < ApplicationRecord
  belongs_to :user
  belongs_to :suggested_user, class_name: 'User', optional: true
  belongs_to :suggested_entourage, class_name: 'Entourage', optional: true

  enum suggestion_type: { connection: 'connection', next_step: 'next_step' }, _prefix: :type
  enum reason_type: { zone: 'zone', event: 'event', group: 'group' }, _prefix: :reason

  validates :suggestion_type, :reason, :reason_type, :expires_at, presence: true

  scope :active, -> {
    where(actioned_at: nil)
      .where('dismissed_at IS NULL OR dismissed_until < ?', Time.current)
      .where('expires_at > ?', Time.current)
  }

  scope :for_type, ->(type) { where(suggestion_type: type) }
end
