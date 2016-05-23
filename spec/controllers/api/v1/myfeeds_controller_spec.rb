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
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, user: user, created_at: 1.hour.ago) }
        let!(:join_request_created) { FactoryGirl.create(:join_request, joinable: entourage_i_created, user: user, status: JoinRequest::ACCEPTED_STATUS) }
        let!(:entourage_i_joined) { FactoryGirl.create(:entourage, created_at: 2.hour.ago) }
        let!(:join_request_joined) { FactoryGirl.create(:join_request, joinable: entourage_i_joined, user: user, status: JoinRequest::ACCEPTED_STATUS) }
        before { get :index, token: user.token }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id]) }
      end
    end
  end
end