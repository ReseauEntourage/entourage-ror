class AdminNote < ApplicationRecord
  NOTABLE_TYPES = %w(User Entourage).freeze

  belongs_to :notable, polymorphic: true
  belongs_to :author, class_name: 'User', optional: true

  validates :body, presence: true
  validates :notable_type, inclusion: { in: NOTABLE_TYPES }

  default_scope { order(created_at: :desc) }
end
