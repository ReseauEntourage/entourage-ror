class SensitiveWordsCheck < ApplicationRecord
  belongs_to :record, polymorphic: true
  serialize :matches
end
