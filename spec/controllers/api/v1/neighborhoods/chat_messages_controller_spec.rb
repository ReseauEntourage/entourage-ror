require 'rails_helper'

describe Api::V1::Neighborhoods::ChatMessagesController do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:neighborhood) { create :neighborhood }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user, image_url: "foo", created_at: Time.now) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user, parent: chat_message_1) }

    before { ChatMessage.stub(:url_for) { "http://foo.bar"} }

    context "not signed in" do
      before { get :index, params: { neighborhood_id: neighborhood.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in neighborhood" do
      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
    end

    context "signed and in neighborhood" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to eq({
        "chat_messages" => [{
          "id" => chat_message_1.id,
          "message_type" => "text",
          "content" => chat_message_1.content,
          "user" => {
            "id" => user.id,
            "avatar_url" => nil,
            "display_name" => "John D.",
            "partner" => nil
          },
          "created_at" => chat_message_1.created_at.iso8601(3),
          "post_id" => nil,
          "has_comments" => true,
          "comments_count" => 1,
          "image_url" => "http://foo.bar",
          "read" => false
        }]
      }) }
    end

    context 'chat_message has been read' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted, last_message_read: Time.now) }

      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }
      it { expect(result['chat_messages'][0]['read']).to eq(true) }
      it { expect(JoinRequest.last.last_message_read.to_s).to eq(chat_message_1.created_at.to_s) }
    end

    context 'chat_message has not been read' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted, last_message_read: 1.day.ago) }

      before { get :index, params: { neighborhood_id: neighborhood.to_param, token: user.token } }
      it { expect(result['chat_messages'][0]['read']).to eq(false) }
      it { expect(JoinRequest.last.last_message_read.to_s).to eq(chat_message_1.created_at.to_s) }
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar"} } }

      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in but not in neighborhood" do
      before { post :create, params: {
        neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar", message_type: :text }, token: user.token
      } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'neighborhood') }
      let!(:android_app) { FactoryBot.create(:android_app, name: 'neighborhood') }

      context "nested chat_messages" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }
        let(:parent_id) { nil }
        let(:has_comments) { false }

        let(:json) {{
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
            "post_id" => parent_id,
            "has_comments" => has_comments,
            "comments_count" => 0,
            "image_url" => nil,
            "read" => nil
          }
        }}

        before { post :create, params: {
          neighborhood_id: neighborhood.to_param, chat_message: { content: "foobar", message_type: :text, parent_id: parent_id }, token: user.token
        } }

        context "no nested" do
          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
        end

        context "with nested" do
          let!(:chat_message) { FactoryBot.create(:chat_message, messageable: neighborhood) }
          let(:parent_id) { chat_message.id }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(2) }
          it { expect(result).to eq(json) }
        end
      end

      describe "send push notif" do
        it "sends notif to everyone accepted except message sender" do
          join_request = FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted)
          join_request2 = FactoryBot.create(:join_request, joinable: neighborhood, status: :accepted)

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

  describe 'GET comments' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user, parent: chat_message_1) }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

    let(:request) { get :comments, params: { neighborhood_id: neighborhood.to_param, id: chat_message_1.id, token: user.token } }

    context "signed and in neighborhood" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to eq({
        "chat_messages" => [{
          "id" => chat_message_2.id,
          "message_type" => "text",
          "content" => chat_message_2.content,
          "user" => {
            "id" => user.id,
            "avatar_url" => nil,
            "display_name" => "John D.",
            "partner" => nil
          },
          "created_at" => chat_message_2.created_at.iso8601(3),
          "post_id" => chat_message_1.id,
          "has_comments" => false,
          "comments_count" => 0,
          "image_url" => nil,
          "read" => false
        }]
      }) }
    end

    context "ordered" do
      let!(:chat_message_3) { FactoryBot.create(:chat_message, messageable: neighborhood, user: user, parent: chat_message_1, created_at: chat_message_2.created_at + day) }

      before { request }

      context "in one order" do
        let(:day) { - 1.day }

        it { expect(result["chat_messages"].count).to eq(2) }
        it { expect(result["chat_messages"][0]["id"]).to eq(chat_message_2.id) }
        it { expect(result["chat_messages"][1]["id"]).to eq(chat_message_3.id) }
      end

      context "in another order" do
        let(:day) { + 1.day }

        it { expect(result["chat_messages"].count).to eq(2) }
        it { expect(result["chat_messages"][0]["id"]).to eq(chat_message_3.id) }
        it { expect(result["chat_messages"][1]["id"]).to eq(chat_message_2.id) }
      end
    end
  end

  describe 'POST #presigned_upload' do
    let(:request) { post :presigned_upload, params: { neighborhood_id: neighborhood.to_param, token: token, content_type: 'image/jpeg' } }

    context "not signed in" do
      let(:token) { nil }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in neighborhood" do
      let(:token) { user.token }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in and in neighborhood" do
      let(:token) { user.token }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: neighborhood, user: user, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('upload_key') }
      it { expect(JSON.parse(response.body)).to have_key('presigned_url') }
    end
  end
end
