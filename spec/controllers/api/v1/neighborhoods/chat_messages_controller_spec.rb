require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessagesController do
  let(:neighborhood) { create :neighborhood }

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar"} } }
      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in" do
      let(:user) { FactoryBot.create(:pro_user) }

      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'neighborhood') }
      let!(:android_app) { FactoryBot.create(:android_app, name: 'neighborhood') }

      context "valid params" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: "accepted") }

        before { post :create, params: {
          neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar", message_type: :text }, token: user.token
        } }

        let(:result) { JSON.parse(response.body) }

        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(1) }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_message" => {
            "id" => ChatMessage.first.id,
            "message_type" => "text",
            "content" => "foobar",
            "user" => {
              "id" => user.id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil
            },
            "created_at" => ChatMessage.first.created_at.iso8601(3),
            "parent_id" => nil
          }
        }) }
      end

      context "valid params with parent_id" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: "accepted") }
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood) }

        before { post :create, params: {
          neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar", message_type: :text, parent_id: chat_message.id }, token: user.token
        } }

        let(:result) { JSON.parse(response.body) }

        it { expect(response.status).to eq(201) }
        it { expect(ChatMessage.count).to eq(2) }
        it { expect(JSON.parse(response.body)).to eq({
          "chat_message" => {
            "id" => ChatMessage.last.id,
            "message_type" => "text",
            "content" => "foobar",
            "user" => {
              "id" => user.id,
              "avatar_url" => nil,
              "display_name" => "John D.",
              "partner" => nil
            },
            "created_at" => ChatMessage.last.created_at.iso8601(3),
            "parent_id" => chat_message.id
          }
        }) }
      end

      describe "send push notif" do
        it "sends notif to everyone accepted except message sender" do
          join_request = FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: "accepted")
          join_request2 = FactoryBot.create(:join_request, joinable: neighborhood, status: "accepted")

          FactoryBot.create(:join_request, joinable: neighborhood, status: "pending")

          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
            "John D.",
            'Foot Paris 17è',
            'foobaz',
            [ neighborhood.user, join_request2.user ],
            {
              joinable_id: neighborhood.id,
              joinable_type: "Neighborhood",
              group_type: 'neighborhood',
              type: "NEW_CHAT_MESSAGE"
            }
          )

          post :create, params: { neighborhood_id: neighborhood.to_param, chat_message: { content: "foobaz" }, token: user.token }
        end
      end
    end
  end
end
