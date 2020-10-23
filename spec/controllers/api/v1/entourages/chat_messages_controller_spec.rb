require 'rails_helper'
include CommunityHelper

describe Api::V1::Entourages::ChatMessagesController do

  let(:entourage) { FactoryGirl.create(:entourage) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index, entourage_id: entourage.to_param }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }

      context "i belong to the entourage" do
        let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("10/01/2000"), updated_at: DateTime.parse("10/01/2000")) }
        let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: entourage, created_at: DateTime.parse("09/01/2000"), updated_at: DateTime.parse("09/01/2000")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(response.status).to eq(200) }
        it { expect(JSON.parse(response.body)).to eq({"chat_messages"=>
                                                          [{
                                                               "id"=>chat_message1.id,
                                                               "message_type"=>"text",
                                                               "content"=>"MyText",
                                                               "user"=> {"id"=>chat_message1.user_id, "avatar_url"=>nil, "display_name"=>"John D.","partner"=>nil},
                                                               "created_at"=>chat_message1.created_at.iso8601(3)
                                                           },
                                                           {
                                                               "id"=>chat_message2.id,
                                                               "message_type"=>"text",
                                                               "content"=>"MyText",
                                                               "user"=> {"id"=>chat_message2.user_id, "avatar_url"=>nil, "display_name"=>"John D.","partner"=>nil},
                                                               "created_at"=>chat_message2.created_at.iso8601(3)
                                                           }]}) }

        it { expect(join_request.reload.last_message_read).to eq(chat_message1.created_at)}
      end

      context "i request older messages" do
        let!(:chat_messages) { FactoryGirl.create_list(:chat_message, 2, messageable: entourage, created_at: DateTime.parse("10/01/2016")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted", last_message_read: DateTime.parse("20/01/2016")) }
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(join_request.reload.last_message_read).to eq(DateTime.parse("20/01/2016"))}
      end

      context "i don't belong to the tour" do
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i am still in pending status" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "pending") }
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i am rejected from the tour" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "rejected") }
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "i quit the tour" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "cancelled") }
        before { get :index, entourage_id: entourage.to_param, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "pagination" do
        let!(:chat_message1) { FactoryGirl.create(:chat_message, messageable: entourage, updated_at: DateTime.parse("11/01/2016")) }
        let!(:chat_message2) { FactoryGirl.create(:chat_message, messageable: entourage, updated_at: DateTime.parse("09/01/2016")) }
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { get :index, entourage_id: entourage.to_param, token: user.token, before: "10/01/2016" }
        it { expect(JSON.parse(response.body)).to eq({"chat_messages"=>[{
                                                                            "id"=>chat_message2.id,
                                                                            "message_type"=>"text",
                                                                            "content"=>"MyText",
                                                                            "user"=>{"id"=>chat_message2.user.id, "avatar_url"=>nil, "display_name"=>"John D.","partner"=>nil},
                                                                            "created_at"=>chat_message2.created_at.iso8601(3)
                                                                        }]}) }
      end

      context "from a null conversations by list uuid" do
        with_community :pfp
        let!(:entourage) { nil }
        let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
        before { get :index, entourage_id: "1_list_#{user.id}-#{other_user.id}", token: user.token }
        it { expect(JSON.parse(response.body)).to eq("chat_messages"=>[]) }
      end
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"} }
      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryGirl.create(:ios_app, name: 'entourage') }
      let!(:android_app) { FactoryGirl.create(:android_app, name: 'entourage') }
      let(:user) { FactoryGirl.create(:pro_user) }

      context "valid params" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        let!(:join_request2) { FactoryGirl.create(:join_request, joinable: entourage, status: "accepted") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(1) }
        it { expect(JSON.parse(response.body)).to eq({"chat_message"=>
                                                          {"id"=>ChatMessage.first.id,
                                                           "message_type"=>"text",
                                                           "content"=>"foobar",
                                                           "user"=>{"id"=>user.id, "avatar_url"=>nil, "display_name"=>"John D.","partner"=>nil},
                                                           "created_at"=>ChatMessage.first.created_at.iso8601(3)
                                                          }}) }
      end

      describe "send push notif" do
        it "sends notif to everyone accaepted except message sender" do
          join_request = FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted")
          join_request2 = FactoryGirl.create(:join_request, joinable: entourage, status: "accepted")
          FactoryGirl.create(:join_request, joinable: entourage, status: "pending")
          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with("John D.", 'foobar', 'foobaz', [join_request2.user], {:joinable_id=>entourage.id, :joinable_type=>"Entourage", :group_type=>'action', :type=>"NEW_CHAT_MESSAGE"})
          post :create, entourage_id: entourage.to_param, chat_message: {content: "foobaz"}, token: user.token
        end
      end

      context "invalid params" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: nil}, token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(ChatMessage.count).to eq(0) }
      end

      context "post in a entourage i don't belong to" do
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i am still in pending status" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "pending") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i am rejected from" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "rejected") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "post in a entourage i have quit" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "cancelled") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar"}, token: user.token }
        it { expect(response.status).to eq(401) }
      end

      context "invalid message type" do
        let!(:join_request) { FactoryGirl.create(:join_request, joinable: entourage, user: user, status: "accepted") }
        before { post :create, entourage_id: entourage.to_param, chat_message: {content: "foobar", message_type: "status_update"}, token: user.token }
        it { expect(response.status).to eq(400) }
        it { expect(JSON.parse(response.body)).to eq("message"=>"Could not create chat message",
                                                     "reasons"=>["Message type n'est pas inclus(e) dans la liste"]) }
      end

      context "pfp visit" do
        with_community :pfp

        let(:circle) { create :private_circle, title: "Les amis de Henriette" }
        let(:user) { create :public_user }
        let!(:join_request) { create :join_request, joinable: circle, user: user, status: :accepted }

        before { post :create, entourage_id: circle.to_param, chat_message: payload, token: user.token }

        context "valid payload" do
          let(:payload) do
            {
              message_type: 'visit',
              metadata: {
                visited_at: Time.zone.now.iso8601
              }
            }
          end

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({"chat_message"=>{
                                                          "id"=>ChatMessage.last.id,
                                                          "message_type"=>"visit",
                                                          "content"=>"J'ai voisiné Henriette aujourd'hui",
                                                          "user"=>{
                                                            "id"=>user.id,
                                                            "avatar_url"=>nil,
                                                            "display_name"=>"John D.",
                                                            "partner"=>nil
                                                          },
                                                          "created_at"=>ChatMessage.last.created_at.iso8601(3)}}) }
        end
      end

      context "to a null conversations by list uuid" do
        with_community :pfp
        let!(:entourage) { nil }
        let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
        let(:join_requests) { Entourage.last.join_requests.map(&:attributes) }
        before { post :create, entourage_id: "1_list_#{user.id}-#{other_user.id}", chat_message: {content: content}, token: user.token }

        context "valid params" do
          let(:content) { "foobar" }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({"chat_message"=>{
                                                          "id"=>ChatMessage.first.id,
                                                          "message_type"=>"text",
                                                          "content"=>"foobar",
                                                          "user"=>{"id"=>user.id, "avatar_url"=>nil, "display_name"=>"John D.","partner"=>nil},
                                                          "created_at"=>ChatMessage.first.created_at.iso8601(3)
                                                       }}) }
          it { expect(Entourage.last.attributes).to include("user_id"=>user.id,
                                                            "number_of_people"=>2,
                                                            "community"=>'pfp',
                                                            "group_type"=>"conversation"
                                                           ) }
          it { expect(Entourage.last.attributes['uuid_v2']).to start_with '1_hash_' }
          it { expect(join_requests.map { |r| r['user_id'] }.sort).to eq([user.id, other_user.id]) }
          it { expect(join_requests.map { |r| r.slice('status', 'role') }.uniq).to eq(["status"=>"accepted", "role"=>"participant"]) }
        end

        context "invalid params" do
          let(:content) { nil }

          it { expect(response.status).to eq(400) }
          it { expect(ChatMessage.count).to eq(0) }
          it { expect(Entourage.count).to eq(0) }
          it { expect(JoinRequest.count).to eq(0) }
        end
      end

      context "share" do
        let(:user) { create :public_user }
        let(:conversation) { create :conversation, participants: [user] }

        before { post :create, entourage_id: conversation.to_param, chat_message: payload, token: user.token }

        context "entourage" do
          let(:entourage) { create :entourage }
          let(:payload) do
            {
              message_type: 'share',
              metadata: {
                type: 'entourage',
                uuid: entourage.uuid_v2
              }
            }
          end

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({
            "chat_message" => {
              "id" => ChatMessage.last.id,
              "content" => "#{entourage.title}\nhttps://www.entourage.social/entourages/#{entourage.uuid_v2}",
              "user" => {
                "id" => user.id,
                "avatar_url" => nil,
                "display_name" => "John D.",
                "partner" => nil
              },
              "created_at" => ChatMessage.last.created_at.iso8601(3),
              "message_type" => "share",
              "metadata" => {
                "type" => "entourage",
                "uuid" => entourage.uuid_v2,
                "$id" => "urn:chat_message:share:metadata"
              }
            }
          })}
        end

        context "poi" do
          let(:poi) { create :poi }
          let(:payload) do
            {
              message_type: 'share',
              metadata: {
                type: 'poi',
                uuid: poi.id
              }
            }
          end

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(JSON.parse(response.body)).to eq({
            "chat_message" => {
              "id" => ChatMessage.last.id,
              "content" => "Dede\nAu 50 75008 Paris",
              "user" => {
                "id" => user.id,
                "avatar_url" => nil,
                "display_name" => "John D.",
                "partner" => nil
              },
              "created_at" => ChatMessage.last.created_at.iso8601(3),
              "message_type" => "share",
              "metadata" => {
                "type" => "poi",
                "uuid" => poi.id.to_s,
                "$id" => "urn:chat_message:share:metadata"
              }
            }
          })}
        end
      end
    end
  end
end
