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
                                       "author"=>{
                                           "id"=>entourage.user.id,
                                           "display_name"=>"John",
                                           "avatar_url"=>nil,
                                           "partner"=>nil
                                       },
                                       "location"=>{
                                           "latitude"=>1.122,
                                           "longitude"=>2.345
                                       },
                                       "join_status"=>"not_requested",
                                       "number_of_unread_messages"=>nil,
                                       "created_at"=> entourage.created_at.iso8601(3),
                                       "updated_at"=> entourage.updated_at.iso8601(3),
                                       "description" => nil,
                                       "share_url" => "http://entourage.social/entourages/#{entourage.uuid}"
                                    }]
                              })
      end

      context "no params" do
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(1) }
      end

      context "order recents entourages" do
        let!(:entourage1) { FactoryGirl.create(:entourage, updated_at: entourage.created_at - 2.hours, created_at: entourage.created_at - 2.hours) }
        let!(:entourage2) { FactoryGirl.create(:entourage, updated_at: entourage.created_at - 3.days, created_at: entourage.created_at - 3.days) }
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
      end

      context "entourages made by other users" do
        let!(:another_entourage) { FactoryGirl.create(:entourage, status: "open") }
        before { get :index, token: user.token }
        it { expect(subject["entourages"].count).to eq(2) }
      end

      context "scope by visible state" do
        let!(:open_entourage)        { FactoryGirl.create(:entourage, status: "open") }
        let!(:closed_entourage)      { FactoryGirl.create(:entourage, status: "closed") }
        let!(:blacklisted_entourage) { FactoryGirl.create(:entourage, status: "blacklisted") }

        before { get :index, token: user.token }
        it { expect(subject["entourages"].map{ |e| e['id'] }).to match_array([entourage.id, open_entourage.id, closed_entourage.id]) }
      end

      context "filter status" do
        let!(:closed_entourage) { FactoryGirl.create(:entourage, status: "closed") }
        before { get :index, status: "closed", token: user.token }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(closed_entourage.id) }
      end

      context "filter entourage_type" do
        let!(:help_entourage) { FactoryGirl.create(:entourage, entourage_type: "ask_for_help", updated_at: entourage.created_at-1.hours, created_at: entourage.created_at-1.hours) }
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
      before { post :create, entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help" } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      it "creates an entourage" do
        expect {
          post :create, entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help" }, token: user.token
        }.to change { Entourage.count }.by(1)
      end

      context "valid params" do
        before { post :create, entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", description: "foo bar", category: "mat_help"}, token: user.token }
        it { expect(JSON.parse(response.body)).to eq({"entourage"=>
                                                          {"id"=>Entourage.last.id,
                                                           "status"=>"open",
                                                           "title"=>"foo",
                                                           "entourage_type"=>"ask_for_help",
                                                           "number_of_people"=>1,
                                                           "author"=>{
                                                               "id"=>user.id,
                                                               "display_name"=>"John",
                                                               "avatar_url"=>nil,
                                                               "partner"=>nil
                                                           },
                                                           "location"=>{
                                                               "latitude"=>4.567,
                                                               "longitude"=>1.123
                                                           },
                                                           "join_status"=>"accepted",
                                                           "number_of_unread_messages"=>0,
                                                           "created_at"=> Entourage.last.created_at.iso8601(3),
                                                           "updated_at"=> Entourage.last.updated_at.iso8601(3),
                                                           "description"=> "foo bar",
                                                           "share_url" => "http://entourage.social/entourages/#{Entourage.last.uuid}"
                                                          }
                                                     }) }
        it { expect(response.status).to eq(201) }
        it { expect(Entourage.last.longitude).to eq(1.123) }
        it { expect(Entourage.last.latitude).to eq(4.567) }
        it { expect(Entourage.last.number_of_people).to eq(1) }
        it { expect(Entourage.last.category).to eq("mat_help") }
        it { expect(user.entourage_participations).to eq([Entourage.last]) }
        it { expect(JoinRequest.count).to eq(1) }
        it { expect(JoinRequest.last.status).to eq(JoinRequest::ACCEPTED_STATUS) }
      end

      context "invalid params" do
        before { post :create, entourage: { location: {longitude: "", latitude: 4.567}, title: "foo", entourage_type: "ask_for_help" }, token: user.token }
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
                                                           "author"=>{
                                                               "id"=>entourage.user.id,
                                                               "display_name"=>"John",
                                                               "avatar_url"=>nil,
                                                               "partner"=>nil
                                                           },
                                                           "location"=>{
                                                               "latitude"=>1.122,
                                                               "longitude"=>2.345
                                                           },
                                                           "join_status"=>"not_requested",
                                                           "number_of_unread_messages"=>nil,
                                                           "created_at"=> entourage.created_at.iso8601(3),
                                                           "updated_at"=> entourage.updated_at.iso8601(3),
                                                           "description" => nil,
                                                           "share_url" => "http://entourage.social/entourages/#{entourage.uuid}"
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

      describe "create entourage display" do
        context "has distance and feed_rank and source" do
          before { get :show, id: entourage.to_param, token: user.token, distance: 123.45, feed_rank: 2, source: "foo" }
          it { expect(EntourageDisplay.count).to eq(1) }
          it { expect(EntourageDisplay.last.distance).to eq(123.45) }
          it { expect(EntourageDisplay.last.feed_rank).to eq(2) }
          it { expect(EntourageDisplay.last.source).to eq("foo") }
        end

        context "has distance and feed_rank but no source" do
          before { get :show, id: entourage.to_param, token: user.token, distance: 123.45, feed_rank: 2 }
          it { expect(EntourageDisplay.count).to eq(1) }
          it { expect(EntourageDisplay.last.distance).to eq(123.45) }
          it { expect(EntourageDisplay.last.feed_rank).to eq(2) }
          it { expect(EntourageDisplay.last.source).to be_nil }
        end

        context "no distance or feed_rank" do
          before { get :show, id: entourage.to_param, token: user.token }
          it { expect(EntourageDisplay.count).to eq(0) }
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
                                                           "author"=>{
                                                               "id"=>user.id,
                                                               "display_name"=>"John",
                                                               "avatar_url"=>nil,
                                                               "partner"=>nil
                                                           },
                                                           "location"=>{
                                                               "latitude"=>1.122,
                                                               "longitude"=>2.345
                                                           },
                                                           "join_status"=>"not_requested",
                                                           "number_of_unread_messages"=>nil,
                                                           "created_at"=> user_entourage.created_at.iso8601(3),
                                                           "updated_at"=> user_entourage.reload.updated_at.iso8601(3),
                                                           "description" => nil,
                                                           "share_url" => "http://entourage.social/entourages/#{user_entourage.uuid}"
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

      context "update location" do
        let!(:user_entourage) { FactoryGirl.create(:entourage, user: user) }
        before { patch :update, id: user_entourage.to_param, entourage: {location: {latitude: 10.5, longitude: 20.1}}, token: user.token }
        it { expect(user_entourage.reload.latitude).to eq(10.5) }
        it { expect(user_entourage.reload.longitude).to eq(20.1) }
      end
    end
  end

  describe "PUT read" do
    let!(:entourage) { FactoryGirl.create(:entourage) }

    context "not signed in" do
      before { put :read, id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "user is accepted in entourage" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: JoinRequest::ACCEPTED_STATUS, last_message_read: old_date) }
      before { put :read, id: entourage.to_param, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to be > old_date }
    end

    context "user is not accepted in entourage" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: JoinRequest::PENDING_STATUS, last_message_read: old_date) }
      before { put :read, id: entourage.to_param, token: user.token }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to eq(old_date) }
    end
  end
end
