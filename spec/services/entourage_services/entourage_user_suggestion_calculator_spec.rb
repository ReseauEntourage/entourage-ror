require 'rails_helper'

RSpec.describe EntourageServices::EntourageUserSuggestionsCalculator do

  describe 'compute' do
    context "nothing to compute" do
      before { expect_any_instance_of(EntourageServices::ScoreCalculator).to receive(:calculate).never }
      before { described_class.compute }

      it { expect(SuggestionComputeHistory.count).to eq(1) }
      it { expect(SuggestionComputeHistory.last.user_number).to eq(0) }
      it { expect(SuggestionComputeHistory.last.total_user_number).to eq(0) }
      it { expect(SuggestionComputeHistory.last.entourage_number).to eq(0) }
      it { expect(SuggestionComputeHistory.last.total_entourage_number).to eq(0) }
      it { expect(SuggestionComputeHistory.last.duration).to eq(0) }
    end

    context "2 users and 3 entourages" do
      let!(:users_suggestion) { FactoryGirl.create_list(:public_user, 2, use_suggestions: true) }
      let!(:users_no_suggestion) { FactoryGirl.create(:public_user, use_suggestions: false) }
      let!(:entourages_suggestion) { FactoryGirl.create_list(:entourage, 3, use_suggestions: true) }
      let!(:entourages_no_suggestion) { FactoryGirl.create(:entourage, use_suggestions: false) }

      it "computes user entourage score" do
        calculator = double()
        allow(EntourageServices::ScoreCalculator).to receive(:new) { calculator }
        allow(calculator).to receive(:calculate).exactly(6).times
        described_class.compute
      end

      it "stores suggestion history" do
        described_class.compute
        expect(SuggestionComputeHistory.count).to eq(1)
        expect(SuggestionComputeHistory.last.user_number).to eq(2)
        expect(SuggestionComputeHistory.last.total_user_number).to eq(7)
        expect(SuggestionComputeHistory.last.entourage_number).to eq(3)
        expect(SuggestionComputeHistory.last.total_entourage_number).to eq(4)
        expect(SuggestionComputeHistory.last.duration).to eq(0)
      end
    end
  end
end
