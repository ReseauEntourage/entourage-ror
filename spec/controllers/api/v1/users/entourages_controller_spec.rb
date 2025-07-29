require 'rails_helper'

describe Api::V1::Users::EntouragesController, type: :controller do
  render_views

  let(:user) { FactoryBot.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not logged in" do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      let!(:entourage_created) { FactoryBot.create(:entourage, user: user, created_at: 1.day.ago) }
      let!(:join_request_created) { FactoryBot.create(:join_request, joinable: entourage_created, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_joined) { FactoryBot.create(:entourage, created_at: 2.day.ago) }
      let!(:join_request_joinded) { FactoryBot.create(:join_request, joinable: entourage_joined, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_other) { FactoryBot.create(:entourage) }
      before { get :index, params: { user_id: user.id, token: user.token } }
      it { expect(response.status).to eq(200) }
      it { expect(result["entourages"].count).to eq(2) }
      it { expect(result["entourages"].map {|entourages| entourages["id"]}).to eq([entourage_created.id, entourage_joined.id]) }
    end

    context "filter entourage status" do
      let!(:entourage_joined_opened) { FactoryBot.create(:entourage, created_at: 2.day.ago, status: "open") }
      let!(:join_request1) { FactoryBot.create(:join_request, joinable: entourage_joined_opened, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_joined_closed) { FactoryBot.create(:entourage, created_at: 2.day.ago, status: "closed") }
      let!(:join_request2) { FactoryBot.create(:join_request, joinable: entourage_joined_closed, user: user, status: JoinRequest::ACCEPTED_STATUS) }

      it "returns opened entourages" do
        get :index, params: { user_id: user.id, token: user.token, status: "open" }
        expect(result["entourages"].count).to eq(1)
        expect(result["entourages"][0]["id"]).to eq(entourage_joined_opened.id)
      end

      it "returns closed entourages" do
        get :index, params: { user_id: user.id, token: user.token, status: "closed" }
        expect(result["entourages"].count).to eq(1)
        expect(result["entourages"][0]["id"]).to eq(entourage_joined_closed.id)
      end
    end
  end
end
