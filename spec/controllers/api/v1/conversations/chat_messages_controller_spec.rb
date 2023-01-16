require 'rails_helper'

describe Api::V1::Conversations::ChatMessagesController do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:conversation) { create :conversation }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: conversation, user: user, created_at: 1.hour.ago) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: conversation, user: user) }

    before { Timecop.freeze }
    before { ChatMessage.stub(:url_for_with_size) { "http://foo.bar"} }

    context "not signed in" do
      before { get :index, params: { conversation_id: conversation.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in conversation" do
      before { get :index, params: { conversation_id: conversation.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
    end

    context "signed and in conversation" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

      before { get :index, params: { conversation_id: conversation.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to eq({
        "chat_messages" => [{
          "id" => chat_message_1.id,
          "content" => chat_message_1.content,
          "user" => {
            "id" => user.id,
            "avatar_url" => nil,
            "display_name" => "John D."
          },
          "created_at" => chat_message_1.created_at.iso8601(3),
          "post_id" => nil,
          "has_comments" => false,
          "comments_count" => 0,
          "image_url" => nil,
          "read" => false,
          "message_type" => "text"
        }, {
          "id" => chat_message_2.id,
          "content" => chat_message_2.content,
          "user" => {
            "id" => user.id,
            "avatar_url" => nil,
            "display_name" => "John D."
          },
          "created_at" => chat_message_2.created_at.iso8601(3),
          "post_id" => nil,
          "has_comments" => false,
          "comments_count" => 0,
          "image_url" => nil,
          "read" => false,
          "message_type" => "text"
        }]
      }) }
    end

    context "chat_message read and last_message_read" do
      let(:last_message_read) { join_request.reload.last_message_read.to_s }
      let(:time) { Time.now }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted, last_message_read: time) }

      before { get :index, params: { conversation_id: conversation.to_param, token: user.token } }

      context 'chat_message has been read' do
        it { expect(result['chat_messages'][0]['read']).to eq(true) }
      end

      context 'chat_message has not been read' do
        let(:time) { 1.day.ago }

        it { expect(result['chat_messages'][0]['read']).to eq(false) }
      end

      context 'last_message_read is still Time.now' do
        it { expect(last_message_read).to eq(Time.now.in_time_zone.to_s) }
      end

      context 'last_message_read is always Time.now' do
        let(:time) { 1.day.ago }
        it { expect(last_message_read).to eq(Time.now.in_time_zone.to_s) }
      end
    end
  end

  describe 'POST create' do
    before { Timecop.freeze }

    context "not signed in" do
      before { post :create, params: { conversation_id: conversation.to_param, chat_message: { content: "foobar"} } }

      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in but not in conversation" do
      before { post :create, params: {
        conversation_id: conversation.to_param, chat_message: { content: "foobar", message_type: :text }, token: user.token
      } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'conversation') }
      let!(:android_app) { FactoryBot.create(:android_app, name: 'conversation') }

      context "nested chat_messages" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }
        let(:content) { "foobar" }
        let(:image_url) { nil }
        let(:parent_id) { nil }
        let(:has_comments) { false }

        let(:json) {{
          "chat_message" => {
            "id" => ChatMessage.last.id,
            "content" => content,
            "user" => {
              "id" => user.id,
              "avatar_url" => nil,
              "display_name" => "John D."
            },
            "created_at" => ChatMessage.last.created_at.iso8601(3),
            "post_id" => parent_id,
            "has_comments" => has_comments,
            "comments_count" => 0,
            "image_url" => image_url,
            "read" => nil,
            "message_type" => "text"
          }
        }}

        let(:chat_message_params) { {
          content: content,
          message_type: :text,
          parent_id: parent_id,
          image_url: image_url
        } }

        before {
          ChatMessage.stub(:url_for_with_size) { image_url }

          post :create, params: {
            token: user.token, conversation_id: conversation.to_param, chat_message: chat_message_params
          }
        }

        context "no nested" do
          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
          # create does update last_message_read in ChatServices::ChatMessageBuilder
          it { expect(join_request.reload.last_message_read).to be_a(ActiveSupport::TimeWithZone) }
        end

        context "with image_url and content" do
          let(:image_url) { "path/to/image.jpeg" }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
        end

        context "with image_url and empty content" do
          let(:content) { "" }
          let(:image_url) { "path/to/image.jpeg" }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
        end

        context "with image_url and no content" do
          let(:content) { nil }
          let(:image_url) { "path/to/image.jpeg" }
          let(:chat_message_params) { {
            message_type: :text,
            image_url: image_url
          } }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
        end
      end

      describe "send push notif" do
        it "sends notif to everyone accepted except message sender" do
          join_request = FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted)
          join_request2 = FactoryBot.create(:join_request, joinable: conversation, status: :accepted)

          FactoryBot.create(:join_request, joinable: conversation, status: "pending")

          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
            nil,
            'John D.',
            "foobaz",
            [ join_request2.user ],
            "conversation",
            conversation.id,
            {
              joinable_id: conversation.id,
              joinable_type: "Entourage",
              group_type: 'conversation',
              type: "NEW_CHAT_MESSAGE",
              instance: "conversation",
              instance_id: conversation.id
            }
          )

          post :create, params: { conversation_id: conversation.to_param, chat_message: { content: "foobaz" }, token: user.token }
        end
      end
    end
  end
end
