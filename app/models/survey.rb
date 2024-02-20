class Survey < ApplicationRecord
  # attr questions (jsonb)
  # attr multiple (boolean)

  has_one :chat_message

  def update_summary
    summary = [0] * questions.length

    chat_message.user_survey_responses.each do |response|
      response.responses.each_with_index do |answer, index|
        summary[index] += 1 if answer
      end
    end

    self.summary = summary

    save
  end
end
