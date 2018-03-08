class SensitiveWordsCheck < ActiveRecord::Base
  belongs_to :record
  serialize :matches
end
