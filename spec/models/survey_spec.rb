require 'rails_helper'

RSpec.describe Survey, :type => :model do
  describe "questions" do
    let(:survey) { create :survey, questions: ["foo", "bar"] }

    it { expect(survey.questions).to eq(["foo", "bar"]) }
  end
end
