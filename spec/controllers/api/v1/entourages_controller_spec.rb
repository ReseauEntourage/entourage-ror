require 'rails_helper'

describe Api::V1::EntouragesController do

  let(:user) { FactoryGirl.create(:public_user) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:entourage) { FactoryGirl.create(:entourage, user: user, status: "open") }
      subject { JSON.parse(response.body) }

      it "renders JSON response" do
        get :index, token: user.token
        expect(subject).to eq({"entourages"=>
                                   [{
                                       "id" => entourage.id,
                                       "status"=>"open",
                                       "title"=>"foobar",
                                       "entourage_type"=>"ask_for_help",
                                       "number_of_people"=>1,
                                       "author"=>{"id"=>user.id, "name"=>"John"},
                                       "location"=>{"latitude"=>2.345, "longitude"=>2.345},
                                       "join_status"=>"not_requested",
                                       "number_of_unread_messages"=>nil
                                    }]
                              })
      end

      context "no params" do
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(1) }
      end

      context "order recents entourages" do
        let!(:very_old_entourage) { FactoryGirl.create(:entourage, created_at: entourage.created_at - 2.months) }
        let!(:old_entourage) { FactoryGirl.create(:entourage, created_at: entourage.created_at - 1.days) }
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
      end

      context "entourages made by other users" do
        let!(:another_entourage) { FactoryGirl.create(:entourage, status: "open") }
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(2) }
      end

      context "filter status" do
        let!(:closed_entourage) { FactoryGirl.create(:entourage, status: "closed") }
        before { get :index, status: "closed", token: user.token }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(closed_entourage.id) }
      end

      context "filter entourage_type" do
        let!(:help_entourage) { FactoryGirl.create(:entourage, entourage_type: "ask_for_help", created_at: entourage.created_at-1.days) }
        before { get :index, type: "ask_for_help", token: user.token }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
      end

      context "filter position" do
        let!(:near_entourage) { FactoryGirl.create(:entourage, latitude: 2.48, longitude: 40.5) }
        before { get :index, latitude: 2.48, longitude: 40.5, token: user.token }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(near_entourage.id) }
      end
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      it "creates an entourage" do
        expect {
          post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token
        }.to change { Entourage.count }.by(1)
      end

      context "valid params" do
        before { post :create, entourage: { longitude: 1.123, latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>
                                                          {"id"=>Entourage.last.id,
                                                           "status"=>"open",
                                                           "title"=>"foo",
                                                           "entourage_type"=>"ask_for_help",
                                                           "number_of_people"=>0,
                                                           "author"=>{"id"=>user.id, "name"=>"John"},
                                                           "location"=>{"latitude"=>1.123, "longitude"=>1.123},
                                                           "join_status"=>"pending",
                                                           "number_of_unread_messages"=>0
                                                          }
                                                     }) }
        it { expect(response.status).to eq(201) }
        it { expect(user.entourage_participations).to eq([Entourage.last]) }
      end

      context "invalid params" do
        before { post :create, entourage: { longitude: "", latitude: 4.567, title: "foo", entourage_type: "ask_for_help" }, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not create entourage", "reasons"=>["Longitude doit être rempli(e)"]}) }
        it { expect(response.status).to eq(400) }
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
      context "entourage exists" do
        before { get :show, id: entourage.to_param, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>
                                                          {"id"=>entourage.id,
                                                           "status"=>"open",
                                                           "title"=>"foobar",
                                                           "entourage_type"=>"ask_for_help",
                                                           "number_of_people"=>1,
                                                           "author"=>{"id"=>entourage.user.id, "name"=>"John"},
                                                           "location"=>{"latitude"=>2.345, "longitude"=>2.345},
                                                           "join_status"=>"not_requested",
                                                           "number_of_unread_messages"=>nil
                                                          }
                                                     }) }
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

  describe 'PATCH update' do
    let!(:entourage) { FactoryGirl.create(:entourage) }

    context "not signed in" do
      before { patch :update, id: entourage.to_param, entourage: {title: "new_title"} }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:user_entourage) { FactoryGirl.create(:entourage, user: user) }

      context "entourage exists" do
        before { patch :update, id: user_entourage.to_param, entourage: {title: "new_title"}, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>
                                                          {"id"=>user_entourage.id,
                                                           "status"=>"open",
                                                           "title"=>"new_title",
                                                           "entourage_type"=>"ask_for_help",
                                                           "number_of_people"=>1,
                                                           "author"=>{"id"=>user.id, "name"=>"John"},
                                                           "location"=>{"latitude"=>2.345, "longitude"=>2.345},
                                                           "join_status"=>"not_requested",
                                                           "number_of_unread_messages"=>nil
                                                          }
                                                     }) }
      end

      context "entourage does not belong to user" do
        before { patch :update, id: entourage.to_param, entourage: {title: "new_title"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "entourage doesn't exists" do
        it "return not found" do
          expect {
            patch :update, id: 0, entourage: {title: "new_title"}, token: user.token
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "invalid params" do
        before { patch :update, id: user_entourage.to_param, entourage: {status: "not exist"}, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not update entourage", "reasons"=>["Status n'est pas inclus(e) dans la liste"]}) }
        it { expect(response.status).to eq(400) }
      end
    end
  end
end