class Survey < ApplicationRecord
  # attr choices (jsonb)
  # attr multiple (boolean)

  has_one :chat_message

  after_create :update_summary

  def update_summary
    return unless chat_message # should not happen

    summary = [0] * choices.length

    chat_message.user_survey_responses.each do |response|
      response.responses.each_with_index do |answer, index|
        summary[index] += 1 if answer
      end
    end

    self.summary = summary

    save
  end
end
