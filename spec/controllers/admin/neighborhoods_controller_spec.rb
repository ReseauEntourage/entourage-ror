require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodsController do
  let!(:user) { admin_basic_login }

  describe 'GET #index' do
    let(:result) { assigns(:neighborhoods).map(&:id) }

    context "has neighborhoods" do
      let!(:neighborhood_list) { create_list(:neighborhood, 2) }

      before { get :index }

      it { expect(result).to match_array(neighborhood_list.map(&:id)) }
    end

    context "has no neighborhoods" do
      before { get :index }

      it { expect(result).to eq([]) }
    end
  end

  describe "GET #edit" do
    let!(:neighborhood) { create(:neighborhood) }

    before { get :edit, params: { id: neighborhood.to_param } }

    it { expect(assigns(:neighborhood).id).to eq(neighborhood.id) }
  end

  describe "PUT #update" do
    let!(:neighborhood) { create(:neighborhood, name: 'foo') }

    context "common field" do
      before { put :update, params: { id: neighborhood.id, neighborhood: { name: 'bar' } } }

      it { expect(neighborhood.reload.name).to eq('bar')}
    end
  end

  describe "POST message" do
    let(:request) { post :message, params: { id: neighborhood.id, chat_message: { content: "foo" }} }

    context "member" do
      let!(:neighborhood) { create(:neighborhood, participants: [user]) }

      it { expect { request }.not_to change { JoinRequest.count } }
      it { expect { request }.to change { ChatMessage.count }.by(1) }
    end

    context "not a member" do
      let!(:neighborhood) { create(:neighborhood) }

      it { expect { request }.to change { JoinRequest.count }.by(1) }
      it { expect { request }.to change { ChatMessage.count }.by(1) }
    end

    context "cancelled member" do
      let!(:neighborhood) { create(:neighborhood, cancelled_participants: [user]) }

      it { expect { request }.not_to change { JoinRequest.count } }
      it { expect { request }.to change { ChatMessage.count }.by(1) }
    end

    context "cancelled member update join_request status" do
      let!(:neighborhood) { create(:neighborhood, cancelled_participants: [user]) }
      let(:join_request) { JoinRequest.find_by(joinable: neighborhood, user: user) }

      before { request }

      it { expect(join_request.reload.status).to eq(JoinRequest::ACCEPTED_STATUS) }
    end
  end
end
