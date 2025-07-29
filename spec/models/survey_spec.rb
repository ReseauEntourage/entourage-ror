require 'rails_helper'

RSpec.describe Survey, type: :model do
  describe "choices" do
    let(:survey) { create :survey, choices: ["foo", "bar"] }

    it { expect(survey.choices).to eq(["foo", "bar"]) }
  end

  describe "update_summary" do
    let(:survey) { create :survey, choices: ["foo", "bar"] }
    let(:chat_message) { create :chat_message, survey: survey }
    let(:user) { create :user }
    let(:survey_response) { create :survey_response, chat_message: chat_message, user: user, responses: [1, 0] }

    before do
      survey_response
      survey.update_summary
    end

    it { expect(survey.summary).to eq([1, 0]) }
  end
end
