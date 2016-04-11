require 'rails_helper'

describe Api::V1::Entourages::UsersController do

  let(:user) { FactoryGirl.create(:public_user) }
  let(:entourage) { FactoryGirl.create(:entourage) }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join entourage" do
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(JSON.parse(response.body)).to eq("user"=>{"id"=>user.id, "email"=>user.email, "display_name"=>"John Doe", "status"=>"pending", "message"=>nil, "requested_at"=>JoinRequest.last.created_at.iso8601(3)}) }
      end

      context "duplicate request to join entourage" do
        before { JoinRequest.create(user: user, joinable: entourage) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(JSON.parse(response.body)).to eq("message"=>"Could not create entourage participation request", "reasons"=>["Joinable a déjà été ajouté"]) }
        it { expect(response.status).to eq(400) }
      end
    end
  end

  describe "GET index" do
    context "not signed in" do
      before { get :index, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage) }
      before { get :index, entourage_id: entourage.to_param, token: user.token }
      it { expect(JSON.parse(response.body)).to eq({"users"=>[{"id"=>user.id, "email"=>user.email, "display_name"=>"John Doe", "status"=>"pending", "message"=>nil, "requested_at"=>join_request.created_at.iso8601(3)}]}) }
    end
  end

  describe "PATCH update" do
    context "not signed in" do
      before { patch :update, entourage_id: entourage.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage) }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.status).to eq("accepted") }
    end

    context "invalid status" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage) }
      before { patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "foo"}, token: user.token }
      it { expect(response.status).to eq(400) }
      it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not update entourage participation request status", "reasons"=>["Status n'est pas inclus(e) dans la liste"]}) }
    end

    context "user didn't request to join entourage" do
      it "raises not found" do
        expect {
          patch :update, entourage_id: entourage.to_param, id: user.id, user: {status: "accepted"}, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE destroy" do
    context "not signed in" do
      before { delete :destroy, entourage_id: entourage.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:join_request) { JoinRequest.create(user: user, joinable: entourage) }
      before { delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.status).to eq("rejected") }
    end

    context "user didn't request to join entourage" do
      it "raises not found" do
        expect {
          delete :destroy, entourage_id: entourage.to_param, id: user.id, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end