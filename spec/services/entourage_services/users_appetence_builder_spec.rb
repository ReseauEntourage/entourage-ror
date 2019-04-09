require 'rails_helper'

RSpec.describe EntourageServices::UsersAppetenceBuilder do

  let(:user) { FactoryGirl.create(:public_user) }

  describe 'create' do
    context "has entourages" do
      let!(:uncategorized_entourage) { FactoryGirl.create(:entourage, user: user) }
      let!(:social_entourage) { FactoryGirl.create(:entourage, user: user, category: 'social') }
      let!(:mat_help_entourage) { FactoryGirl.create(:entourage, user: user, category: 'mat_help') }
      let!(:non_mat_help_entourage) { FactoryGirl.create(:entourage, user: user, category: 'non_mat_help') }
      let!(:join_request1) { FactoryGirl.create(:join_request, user: user, joinable: uncategorized_entourage, distance: nil) }
      let!(:join_request2) { FactoryGirl.create(:join_request, user: user, joinable: social_entourage, distance: 40) }
      let!(:join_request3) { FactoryGirl.create(:join_request, user: user, joinable: mat_help_entourage, distance: 40) }
      let!(:join_request4) { FactoryGirl.create(:join_request, user: user, joinable: non_mat_help_entourage, distance: 20) }

      describe "create new user_appetence" do
        before { EntourageServices::UsersAppetenceBuilder.new(user: user).create }

        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(10) }
        it { expect(user_appetence.appetence_mat_help).to eq(10) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(10) }
        it { expect(user_appetence.avg_dist).to eq(33.3333333333333) }
      end

      describe "update existing user_appetence" do
        let!(:users_appetence) { FactoryGirl.create(:users_appetence, user: user, appetence_social: 5, appetence_mat_help: 5, appetence_non_mat_help: 5, avg_dist: 5) }
        before { EntourageServices::UsersAppetenceBuilder.new(user: user).create }

        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(10) }
        it { expect(user_appetence.appetence_mat_help).to eq(10) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(10) }
        it { expect(user_appetence.avg_dist).to eq(33.3333333333333) }
      end
    end

    context "no entourages" do
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).create }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(0) }
        it { expect(user_appetence.appetence_mat_help).to eq(0) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(0) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end
  end

  describe "join entourage" do
    let!(:social_entourage) { FactoryGirl.create(:entourage, user: user, category: 'social') }

    context "entourage without category" do
      let!(:unkown_entourage) { FactoryGirl.create(:entourage, user: user) }
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).join_entourage(entourage: unkown_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(0) }
        it { expect(user_appetence.appetence_mat_help).to eq(0) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(0) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end

    context "no previous user appetence" do
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).join_entourage(entourage: social_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(10) }
        it { expect(user_appetence.appetence_mat_help).to eq(0) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(0) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end


    context "has previous user appetence" do
      let!(:users_appetence) { FactoryGirl.create(:users_appetence, user: user, appetence_social: 5, appetence_mat_help: 5, appetence_non_mat_help: 5, avg_dist: 5) }
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).join_entourage(entourage: social_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(15) }
        it { expect(user_appetence.appetence_mat_help).to eq(5) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(5) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end
  end


  describe "view entourage" do
    let!(:social_entourage) { FactoryGirl.create(:entourage, user: user, category: 'social') }

    context "entourage without category" do
      let!(:unkown_entourage) { FactoryGirl.create(:entourage, user: user) }
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).view_entourage(entourage: unkown_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(0) }
        it { expect(user_appetence.appetence_mat_help).to eq(0) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(0) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end

    context "no previous user appetence" do
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).view_entourage(entourage: social_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(1) }
        it { expect(user_appetence.appetence_mat_help).to eq(0) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(0) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end


    context "has previous user appetence" do
      let!(:users_appetence) { FactoryGirl.create(:users_appetence, user: user, appetence_social: 5, appetence_mat_help: 5, appetence_non_mat_help: 5, avg_dist: 5) }
      before { EntourageServices::UsersAppetenceBuilder.new(user: user).view_entourage(entourage: social_entourage) }

      describe "create new user_appetence" do
        let(:user_appetence) { UsersAppetence.last }
        it { expect(UsersAppetence.count).to eq(1) }
        it { expect(user_appetence.appetence_social).to eq(6) }
        it { expect(user_appetence.appetence_mat_help).to eq(5) }
        it { expect(user_appetence.appetence_non_mat_help).to eq(5) }
        it { expect(user_appetence.avg_dist).to eq(150) }
      end
    end
  end
end
