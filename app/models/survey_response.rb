class SurveyResponse < ApplicationRecord
  belongs_to :user
  belongs_to :chat_message
  has_one :survey, through: :chat_message

  after_commit :update_survey_summary

  validates_uniqueness_of :user_id, scope: [:chat_message_id], message: "You can only answer once"

  def update_survey_summary
    return unless survey

    survey.update_summary
  end
end
