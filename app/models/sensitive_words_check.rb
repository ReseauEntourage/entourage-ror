class SensitiveWordsCheck < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :checked_by, class_name: 'User', optional: true
  serialize :matches, JSON
end
