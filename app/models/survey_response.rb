class SurveyResponse < ApplicationRecord
  belongs_to :user
  belongs_to :chat_message
  has_one :survey, through: :chat_message

  after_commit :update_survey_summary

  validates_uniqueness_of :user_id, scope: [:chat_message_id], message: 'Only one answer per user authorized'

  def update_survey_summary
    return unless survey

    survey.update_summary
  end
end
