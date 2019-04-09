require 'rails_helper'

describe Api::V1::Users::EntouragesController, :type => :controller do
  render_views

  let(:user) { FactoryGirl.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not logged in" do
      before { get :index, user_id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      let!(:entourage_created) { FactoryGirl.create(:entourage, user: user, created_at: 1.day.ago) }
      let!(:join_request_created) { FactoryGirl.create(:join_request, joinable: entourage_created, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_joined) { FactoryGirl.create(:entourage, created_at: 2.day.ago) }
      let!(:join_request_joinded) { FactoryGirl.create(:join_request, joinable: entourage_joined, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_other) { FactoryGirl.create(:entourage) }
      before { get :index, user_id: user.id, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(result["entourages"].count).to eq(2) }
      it { expect(result["entourages"].map {|entourages| entourages["id"]}).to eq([entourage_created.id, entourage_joined.id]) }
    end

    context "filter entourage status" do
      let!(:entourage_joined_opened) { FactoryGirl.create(:entourage, created_at: 2.day.ago, status: "open") }
      let!(:join_request1) { FactoryGirl.create(:join_request, joinable: entourage_joined_opened, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_joined_closed) { FactoryGirl.create(:entourage, created_at: 2.day.ago, status: "closed") }
      let!(:join_request2) { FactoryGirl.create(:join_request, joinable: entourage_joined_closed, user: user, status: JoinRequest::ACCEPTED_STATUS) }

      it "returns opened entourages" do
        get :index, user_id: user.id, token: user.token, status: "open"
        expect(result["entourages"].count).to eq(1)
        expect(result["entourages"][0]["id"]).to eq(entourage_joined_opened.id)
      end

      it "returns closed entourages" do
        get :index, user_id: user.id, token: user.token, status: "closed"
        expect(result["entourages"].count).to eq(1)
        expect(result["entourages"][0]["id"]).to eq(entourage_joined_closed.id)
      end
    end
  end
end
