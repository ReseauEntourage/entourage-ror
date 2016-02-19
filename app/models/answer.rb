class Answer < ActiveRecord::Base
  belongs_to :question
  belongs_to :encounter

  validates :encounter_id, :question_id, :value, presence: true
end