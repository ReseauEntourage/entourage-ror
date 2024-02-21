require 'rails_helper'

RSpec.describe Survey, :type => :model do
  describe "choices" do
    let(:survey) { create :survey, choices: ["foo", "bar"] }

    it { expect(survey.choices).to eq(["foo", "bar"]) }
  end
end
