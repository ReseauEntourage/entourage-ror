class SensitiveWordsCheck < ApplicationRecord
  belongs_to :record
  serialize :matches
end
