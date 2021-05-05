class SuggestionComputeHistory < ApplicationRecord
  validates :user_number,
            :total_user_number,
            :entourage_number,
            :total_entourage_number,
            :duration,
            :filter_type, presence: true
end
