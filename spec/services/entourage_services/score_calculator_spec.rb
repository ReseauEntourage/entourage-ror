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

    describe "by appetence" do
      let!(:entourage_user) { FactoryGirl.create(:public_user) }
      let!(:entourage) { FactoryGirl.create(:entourage, user: entourage_user, category: "mat_help") }

      context "no appettence" do
        subject { EntourageServices::ScoreCalculator.new(entourage: entourage, user: entourage_user).final_score }

        it { should eq(0.0) }
      end

      context "with appettence" do
        let!(:user_appetence) { FactoryGirl.create(:users_appetence, user: entourage_user, appetence_social: 1, appetence_mat_help: 2, appetence_non_mat_help: 3) }
        subject {  }

        it "" do
          score = EntourageServices::ScoreCalculator.new(entourage: entourage, user: entourage_user).final_score
          expect(score).to be_within(0.001).of(0.399)
        end
      end
    end

    context "Entourage from entourage organization" do
      let!(:entourage_assos) { FactoryGirl.create(:organization, id: 1) }
      let!(:entourage_user) { FactoryGirl.create(:pro_user, organization: entourage_assos) }
      let!(:entourage) { FactoryGirl.create(:entourage, user: entourage_user, category: "mat_help") }
      let!(:user_appetence) { FactoryGirl.create(:users_appetence, user: entourage_user, appetence_social: 1, appetence_mat_help: 2, appetence_non_mat_help: 3) }

      subject { EntourageServices::ScoreCalculator.new(entourage: entourage, user: entourage_user).final_score }

      it { should be_within(0.001).of(0.479) }
    end

    context "Entourage from atd friend" do
      let!(:atd_user1) { FactoryGirl.create(:public_user, atd_friend: true) }
      let!(:atd_user2) { FactoryGirl.create(:public_user, atd_friend: true) }
      let!(:user1) { FactoryGirl.create(:public_user, atd_friend: false) }
      let!(:user_appetence) { FactoryGirl.create(:users_appetence, user: user1, appetence_social: 1, appetence_mat_help: 2, appetence_non_mat_help: 3) }
      let!(:user_appetence2) { FactoryGirl.create(:users_appetence, user: atd_user2, appetence_social: 1, appetence_mat_help: 2, appetence_non_mat_help: 3) }
      let!(:entourage_by_atd) { FactoryGirl.create(:entourage, user: atd_user1, category: "mat_help") }
      let!(:entourage) { FactoryGirl.create(:entourage, user: user1, category: "mat_help") }

      subject { EntourageServices::ScoreCalculator }

      it "boost atd entourage score for atd friends" do
        expect(subject.new(entourage: entourage_by_atd, user: user1).final_score).to be_within(0.001).of(0.399)
        expect(subject.new(entourage: entourage_by_atd, user: atd_user2).final_score).to be_within(0.001).of(0.479)
      end
    end
  end
end
