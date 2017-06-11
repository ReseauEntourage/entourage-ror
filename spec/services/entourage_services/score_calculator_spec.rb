require 'rails_helper'

RSpec.describe EntourageServices::ScoreCalculator do

  describe 'calculate' do
    let(:entourage) { FactoryGirl.create(:entourage) }
    let(:user) { FactoryGirl.create(:public_user) }

    context "first score" do
      before { EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).calculate }
      let(:entourage_score) { EntourageScore.last }

      it { expect(EntourageScore.count).to eq(1) }
      it { expect(entourage.entourage_score).to eq(entourage_score) }
      it { expect(entourage_score.base_score).to eq(0.0) }
      it { expect(entourage_score.final_score).to eq(0.0) }
    end

    context "update existing score" do
      let!(:existing_entourage_score) { FactoryGirl.create(:entourage_score, user: user, entourage: entourage, base_score: 3.3, final_score: 4.5) }

      before { EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).calculate }
      let(:entourage_score) { EntourageScore.last }

      it { expect(EntourageScore.count).to eq(1) }
      it { expect(entourage.entourage_score).to eq(entourage_score) }
      it { expect(entourage_score.base_score).to eq(0.0) }
      it { expect(entourage_score.final_score).to eq(0.0) }
    end
  end

  describe "base_score" do
    let(:date) { DateTime.parse("25/10/2015 14:59:59") }
    let(:entourage_creator) { FactoryGirl.create(:public_user) }
    let(:entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: entourage_creator, created_at: date) }

    let!(:old_connected_user) { FactoryGirl.create(:public_user, last_sign_in_at: date-1.day) }
    let!(:new_connected_user) { FactoryGirl.create(:public_user, last_sign_in_at: date+1.day) }
    let!(:user) { FactoryGirl.create(:public_user, last_sign_in_at: date+1.day) }
    subject { EntourageServices::ScoreCalculator.new(entourage: entourage, user: entourage_creator).base_score }

    it { should eq(0.25) }
  end

  describe "final_score" do
    context "closed entourage" do
      let(:entourage) { FactoryGirl.create(:entourage, status: 'closed') }
      let(:user) { FactoryGirl.create(:public_user) }
      subject { EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).final_score }

      it { should eq(0.0) }
    end

    context "old entourage" do
      let(:entourage) { FactoryGirl.create(:entourage, updated_at: 1.year.ago) }
      let(:user) { FactoryGirl.create(:public_user) }
      subject { EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).final_score }

      it { should eq(0.0) }
    end
  end
end
