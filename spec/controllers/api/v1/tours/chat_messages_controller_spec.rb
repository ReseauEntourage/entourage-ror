require 'rails_helper'

describe Api::V1::Tours::ChatMessagesController do

  let(:tour) { FactoryGirl.create(:tour) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index, tour_id: tour.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }

      context "i belong to the tour" do
        let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: tour, created_at: DateTime.parse("10/01/2000"), updated_at: DateTime.parse("10/01/2000")) }
        let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: tour, created_at: DateTime.parse("09/01/2000"), updated_at: DateTime.parse("09/01/2000")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted") }
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"chat_messages"=>
                                                          [{
                                                               "id"=>chat_message1.id,
                                                               "message_type"=>"text",
                                                               "content"=>"MyText",
                                                               "user"=> {"id"=>chat_message1.user_id, "avatar_url"=>nil, "display_name"=>"John D","partner"=>nil},
                                                               "created_at"=>chat_message1.created_at.iso8601(3)
                                                           },
                                                           {
                                                               "id"=>chat_message2.id,
                                                               "message_type"=>"text",
                                                               "content"=>"MyText",
                                                               "user"=> {"id"=>chat_message2.user_id, "avatar_url"=>nil, "display_name"=>"John D","partner"=>nil},
                                                               "created_at"=>chat_message2.created_at.iso8601(3)
                                                           }]}) }

        it { expect(join_request.reload.last_message_read).to eq(chat_message2.created_at)}
      end

      context "i request older messages" do
        let!(:chat_messages) { FactoryGirl.create_list(:chat_message, 2, messageable: tour, created_at: DateTime.parse("10/01/2016")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted", last_message_read: DateTime.parse("20/01/2016")) }
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(join_request.reload.last_message_read).to eq(DateTime.parse("20/01/2016"))}
      end

      context "i don't belong to the tour" do
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i am still in pending status" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "pending") }
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i am rejected from the tour" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "rejected") }
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i have quit the tour" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "cancelled") }
        before { get :index, tour_id: tour.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "pagination" do
        let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: tour, updated_at: DateTime.parse("11/01/2016")) }
        let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: tour, updated_at: DateTime.parse("09/01/2016")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted") }
        before { get :index, tour_id: tour.to_param, token: user.token, before: "10/01/2016" }
        it { expect(JSON.parse(response.body)).to eq({"chat_messages"=>[{
                                                                           "id"=>chat_message2.id,
                                                                           "message_type"=>"text",
                                                                           "content"=>"MyText",
                                                                           "user"=>{"id"=>chat_message2.user.id, "avatar_url"=>nil, "display_name"=>"John D","partner"=>nil},
                                                                           "created_at"=>chat_message2.created_at.iso8601(3)
                                                                       }]}) }
      end
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"} }
      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryGirl.create(:ios_app, name: 'entourage') }
      let!(:android_app) { FactoryGirl.create(:android_app, name: 'entourage') }
      let(:user) { FactoryGirl.create(:pro_user) }

      context "valid params" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted") }
        let!(:join_request2) { FactoryGirl.create(:join_request, joinable: tour, status: "accepted") }
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(1) }
        it { expect(JSON.parse(response.body)).to eq({"chat_message"=>
                                                          {"id"=>ChatMessage.first.id,
                                                           "message_type"=>"text",
                                                           "content"=>"foobar",
                                                           "user"=>{"id"=>user.id, "avatar_url"=>nil, "display_name"=>"John D","partner"=>nil},
                                                           "created_at"=>ChatMessage.first.created_at.iso8601(3)
                                                          }}) }
      end

      describe "send push notif" do
        it "sends notif to everyone accaepted except message sender" do
          join_request = FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted")
          join_request2 = FactoryGirl.create(:join_request, joinable: tour, status: "accepted")
          FactoryGirl.create(:join_request, joinable: tour, status: "pending")
          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D", nil, 'foobar', [join_request2.user], {:joinable_id=>tour.id, :joinable_type=>"Tour", :group_type=>'tour', :type=>"NEW_CHAT_MESSAGE"})
          post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token
        end
      end

      context "invalid params" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "accepted") }
        before { post :create, tour_id: tour.to_param, chat_message: {content: nil}, token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(ChatMessage.count).to eq(0) }
      end

      context "post in a tour i don't belong to" do
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a tour i am still in pending status" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "pending") }
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a tour i am rejected from" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "rejected") }
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a tour i have quit" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: tour, user: user, status: "cancelled") }
        before { post :create, tour_id: tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a freezed tour" do
        let(:freezed_tour) { FactoryGirl.create(:tour, status: :freezed) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: freezed_tour, user: user, status: "accepted") }
        before { post :create, tour_id: freezed_tour.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(422) }
      end
    end
  end
end
