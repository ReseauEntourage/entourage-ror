class Question < ActiveRecord::Base
  validates :title, :answer_type, :answer_value, :organization_id, presence: true
end
