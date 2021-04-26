class EntourageDisplay < ApplicationRecord
  belongs_to :entourage, optional: true # about 1% of records have null entourage_id
  belongs_to :user
end
