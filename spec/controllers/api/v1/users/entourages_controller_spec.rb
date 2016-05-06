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
      let!(:entourage_created) { FactoryGirl.create(:entourage, user: user) }
      let!(:join_request_created) { FactoryGirl.create(:join_request, joinable: entourage_created, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_joined) { FactoryGirl.create(:entourage) }
      let!(:join_request_joinded) { FactoryGirl.create(:join_request, joinable: entourage_joined, user: user, status: JoinRequest::ACCEPTED_STATUS) }
      let!(:entourage_other) { FactoryGirl.create(:entourage) }
      before { get :index, user_id: user.id, token: user.token }
      it { expect(response.status).to eq(200) }
      it { expect(result["entourages"].count).to eq(2) }
      it { expect(result["entourages"].map {|entourages| entourages["id"]}).to eq([entourage_joined.id, entourage_created.id]) }
    end
  end
end