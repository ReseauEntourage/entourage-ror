require 'rails_helper'

describe Api::V1::MyfeedsController do

  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }
      let!(:tour) { FactoryGirl.create(:tour, created_at: 5.hours.ago, tour_type: "medical") }
      let!(:entourage) { FactoryGirl.create(:entourage, created_at: 4.hours.ago, entourage_type: "ask_for_help") }

      context "get entourages i'm not part of" do
        before { get :index, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({"feeds"=>[]}) }
      end

      context "get my entourages" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago) }
        let!(:entourage_i_joined) { FactoryGirl.create(:entourage, :joined, join_request_user: user, created_at: 2.hour.ago) }
        before { get :index, token: user.token }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id]) }
      end

      context "filter by status" do
        let!(:entourage_open) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago, status: :open) }
        let!(:entourage_closed) { FactoryGirl.create(:entourage, :joined, join_request_user: user, created_at: 2.hour.ago, status: :closed) }
        let!(:tour_ongoing) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 3.hours.ago, status: :ongoing) }
        let!(:tour_closed) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 4.hours.ago, status: :closed) }
        let!(:tour_freezed) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 5.hours.ago, status: :freezed) }

        context "get active feeds" do
          before { get :index, token: user.token, status: "active" }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_open.id, tour_ongoing.id, tour_closed.id]) }
        end

        context "get active feeds" do
          before { get :index, token: user.token, status: "closed" }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_closed.id, tour_freezed.id]) }
        end
      end

      context "filter created_by_me" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago, status: :open) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, created_at: 1.hour.ago, status: :open) }
        let!(:my_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, created_at: 3.hours.ago, status: :ongoing) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 3.hours.ago, status: :ongoing) }
        before { get :index, token: user.token, created_by_me: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, my_tour.id]) }
      end

      context "filter created_by_me" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago, status: :open) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, created_at: 1.hour.ago, status: :open) }
        let!(:my_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, created_at: 3.hours.ago, status: :ongoing) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 3.hours.ago, status: :ongoing) }
        before { get :index, token: user.token, created_by_me: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, my_tour.id]) }
      end

      context "filter accepted_invitation" do
        let!(:invited_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, created_at: 1.hour.ago, status: :open) }
        let!(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_entourage) }
        let!(:other_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, created_at: 1.hour.ago, status: :open) }
        let!(:other_entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user, invitable: other_entourage) }
        let!(:invited_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, created_at: 3.hours.ago, status: :ongoing) }
        let!(:tour_invitation) { FactoryGirl.create(:entourage_invitation, :accepted, invitee: user, invitable: invited_tour) }
        let!(:other_tour) { FactoryGirl.create(:tour, :joined, join_request_user: user, created_at: 3.hours.ago, status: :ongoing) }
        before { get :index, token: user.token, accepted_invitation: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([invited_entourage.id, invited_tour.id]) }
      end
    end
  end
end