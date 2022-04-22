require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessagesController do
  let(:neighborhood) { create :neighborhood }
  let(:user) { create :pro_user }

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
            "created_at" => ChatMessage.first.created_at.iso8601(3)
          }
        }) }
      end

      describe "send push notif" do
        it "sends notif to everyone accaepted except message sender" do
          join_request = FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: "accepted")
          join_request2 = FactoryBot.create(:join_request, joinable: neighborhood, status: "accepted")

          FactoryBot.create(:join_request, joinable: neighborhood, status: "pending")

          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
            "John D.",
            'Foot Paris 17è',
            'foobaz',
            [ join_request2.user ],
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

  describe 'POST #report' do
    let(:neighborhood) { create :neighborhood }
    let(:chat_message) { create :chat_message, messageable: neighborhood }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: "accepted") }

    ENV['SLACK_SIGNAL_NEIGHBORHOOD_WEBHOOK'] = '{"url":"https://url.to.slack.com","channel":"channel","username":"signal-neighborhood"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "correct messageable" do
      before {
        expect_any_instance_of(SlackServices::SignalNeighborhoodChatMessage).to receive(:notify)
        post :report, params: { token: user.token, neighborhood_id: neighborhood.id, chat_message_id: chat_message.id }
      }
      it { expect(response.status).to eq 201 }
    end

    context "wrong messageable" do
      let(:entourage) { create :entourage }
      let(:entourage_chat_message) { create :chat_message, messageable: entourage }

      before {
        expect_any_instance_of(SlackServices::SignalNeighborhoodChatMessage).not_to receive(:notify)
        post :report, params: { token: user.token, neighborhood_id: neighborhood.id, chat_message_id: entourage_chat_message.id }
      }
      it { expect(response.status).to eq 400 }
    end
  end
end
