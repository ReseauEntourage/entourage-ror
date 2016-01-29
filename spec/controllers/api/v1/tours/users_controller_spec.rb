require 'rails_helper'

describe Api::V1::Tours::UsersController do
  let(:user) { FactoryGirl.create(:user) }
  let(:tour) { FactoryGirl.create(:tour) }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "first request to join tour" do
        before { post :create, tour_id: tour.to_param, token: user.token }
        it { expect(tour.members).to eq([user]) }
        it { expect(JSON.parse(response.body)).to eq("user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe"}) }
      end

      context "duplicate request to join tour" do
        before { ToursUser.create(user: user, tour: tour) }
        before { post :create, tour_id: tour.to_param, token: user.token }
        it { expect(tour.members).to eq([user]) }
        it { expect(JSON.parse(response.body)).to eq("message"=>"Could not create tour participation request", "reasons"=>["Tour a déjà été ajouté"]) }
        it { expect(response.status).to eq(400) }
      end
    end
  end

  describe "GET index" do
    context "not signed in" do
      before { get :index, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:tour_user) { ToursUser.create(user: user, tour: tour) }
      before { get :index, tour_id: tour.to_param, token: user.token }
      it { expect(JSON.parse(response.body)).to eq({"users"=>[{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe"}]}) }
    end
  end

  describe "PATCH update" do
    context "not signed in" do
      before { patch :update, tour_id: tour.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:tour_user) { ToursUser.create(user: user, tour: tour) }
      before { patch :update, tour_id: tour.to_param, id: user.id, user: {status: "accepted"}, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(tour_user.reload.status).to eq("accepted") }
    end

    context "invalid status" do
      let!(:tour_user) { ToursUser.create(user: user, tour: tour) }
      before { patch :update, tour_id: tour.to_param, id: user.id, user: {status: "foo"}, token: user.token }
      it { expect(response.status).to eq(400) }
      it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not update tour participation request status", "reasons"=>["Status n'est pas inclus(e) dans la liste"]}) }
    end

    context "user didn't request to join tour" do
      it "raises not found" do
        expect {
          patch :update, tour_id: tour.to_param, id: user.id, user: {status: "accepted"}, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE destroy" do
    context "not signed in" do
      before { delete :destroy, tour_id: tour.to_param, id: user.id }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:tour_user) { ToursUser.create(user: user, tour: tour) }
      before { delete :destroy, tour_id: tour.to_param, id: user.id, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(tour_user.reload.status).to eq("rejected") }
    end

    context "user didn't request to join tour" do
      it "raises not found" do
        expect {
          delete :destroy, tour_id: tour.to_param, id: user.id, token: user.token
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end