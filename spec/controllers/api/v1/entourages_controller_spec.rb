require 'rails_helper'

describe Api::V1::EntouragesController do
  
  describe 'POST create' do
    context "not signed in" do
      before { post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:user) }

      it "creates an entourage" do
        expect {
          post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token
        }.to change { Entourage.count }.by(1)
      end

      context "valid params" do
        before { post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>{"status"=>"open", "title"=>"foo", "entourage_type"=>"ask_for_help", "number_of_people"=>1, "author"=>{"id"=>user.id, "name"=>"John"}, "location"=>{"latitude"=>1.123, "longitude"=>1.123}}}) }
        it { expect(response.status).to eq(201) }
      end

      context "invalid params" do
        before { post :create, entourage: { longitude: "", latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not create entourage", "reasons"=>["Longitude doit être rempli(e)"]}) }
        it { expect(response.status).to eq(400) }
      end
    end
  end

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:user) { FactoryGirl.create(:user) }
      let!(:user_entourage) { FactoryGirl.create(:entourage, user: user) }
      let!(:entourage) { FactoryGirl.create(:entourage) }
      before { get :index, page: 1, per: 25, token: user.token }

      it "returns only user entourages" do
        expect(JSON.parse(response.body)).to eq({"entourages"=>[{"status"=>"open", "title"=>"foobar", "entourage_type"=>"ask_for_help", "number_of_people"=>1, "author"=>{"id"=>user.id, "name"=>"John"}, "location"=>{"latitude"=>2.345, "longitude"=>2.345}}]})
      end
    end
  end

  describe 'GET show' do
    let!(:entourage) { FactoryGirl.create(:entourage) }

    context "not signed in" do
      before { get :show, id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:user) { FactoryGirl.create(:user) }

      context "entourage exists" do
        before { get :show, id: entourage.to_param, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>{"status"=>"open", "title"=>"foobar", "entourage_type"=>"ask_for_help", "number_of_people"=>1, "author"=>{"id"=>entourage.user.id, "name"=>"John"}, "location"=>{"latitude"=>2.345, "longitude"=>2.345}}}) }
      end

      context "entourage doesn't exists" do
        it "return not found" do
          expect {
              get :show, id: 0, token: user.token
            }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'PUT update' do
    let!(:entourage) { FactoryGirl.create(:entourage) }

    context "not signed in" do
      before { put :update, id: entourage.to_param, entourage: {title: "new_title"} }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:user) { FactoryGirl.create(:user) }
      let!(:user_entourage) { FactoryGirl.create(:entourage, user: user) }

      context "entourage exists" do
        before { put :update, id: user_entourage.to_param, entourage: {title: "new_title"}, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>{"status"=>"open", "title"=>"new_title", "entourage_type"=>"ask_for_help", "number_of_people"=>1, "author"=>{"id"=>user.id, "name"=>"John"}, "location"=>{"latitude"=>2.345, "longitude"=>2.345}}}) }
      end

      context "entourage does not belong to user" do
        before { put :update, id: entourage.to_param, entourage: {title: "new_title"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "entourage doesn't exists" do
        it "return not found" do
          expect {
            put :update, id: 0, entourage: {title: "new_title"}, token: user.token
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "invalid params" do
        before { put :update, id: user_entourage.to_param, entourage: {status: "not exist"}, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not update entourage", "reasons"=>["Status n'est pas inclus(e) dans la liste"]}) }
        it { expect(response.status).to eq(400) }
      end
    end
  end
end