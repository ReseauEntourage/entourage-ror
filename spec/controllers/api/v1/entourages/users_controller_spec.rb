require 'rails_helper'

describe Api::V1::Entourages::UsersController do

  let(:user) { FactoryGirl.create(:user) }
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
        it { expect(JSON.parse(response.body)).to eq("user"=>{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe"}) }
      end

      context "duplicate request to join entourage" do
        before { EntouragesUser.create(user: user, entourage: entourage) }
        before { post :create, entourage_id: entourage.to_param, token: user.token }
        it { expect(entourage.members).to eq([user]) }
        it { expect(JSON.parse(response.body)).to eq("message"=>"Could not create entourage participation request", "reasons"=>["Entourage a déjà été ajouté"]) }
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
      let!(:entourage_user) { EntouragesUser.create(user: user, entourage: entourage) }
      before { get :index, entourage_id: entourage.to_param, token: user.token }
      it { expect(JSON.parse(response.body)).to eq({"users"=>[{"id"=>user.id, "email"=>user.email, "first_name"=>"John", "last_name"=>"Doe"}]}) }
    end
  end
end