require 'rails_helper'

describe Api::V1::Outings::ChatMessagesController do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:outing) { create :outing, title: "Foot Paris 17è" }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: outing, user: user, image_url: "foo", created_at: 1.hour.ago) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: outing, user: user, parent: chat_message_1) }
    let!(:chat_message_3) { FactoryBot.create(:chat_message, :closed_as_success, messageable: outing, user: user, created_at: 1.hour.ago) }

    before { Timecop.freeze }
    before { ChatMessage.stub(:url_for_with_size) { "http://foo.bar"} }

    context "not signed in" do
      before { get :index, params: { outing_id: outing.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in outing" do
      before { get :index, params: { outing_id: outing.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
    end

    context "signed and in outing" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }

      before { get :index, params: { outing_id: outing.to_param, token: user.token } }

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
          "has_comments" => true,
          "comments_count" => 1,
          "image_url" => "http://foo.bar",
          "read" => false,
          "message_type" => "text",
          "status" => "active"
        }]
      }) }
    end

    context "chat_message read and last_message_read" do
      let(:last_message_read) { join_request.reload.last_message_read.to_s }
      let(:time) { Time.now }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted, last_message_read: time) }

      before { get :index, params: { outing_id: outing.to_param, token: user.token } }

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

  describe 'GET show' do
    let!(:chat_message) { FactoryBot.create(:chat_message, messageable: outing) }

    context "not signed in" do
      before { get :show, params: { outing_id: outing.to_param, id: chat_message.id } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in outing" do
      before { get :show, params: { outing_id: outing.to_param, id: chat_message.id, token: user.token } }

      it { expect(response.status).to eq(200) }
    end

    context "signed and in outing" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }

      before { get :show, params: { outing_id: outing.to_param, id: chat_message.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_message')}
      it { expect(result).to eq({
        "chat_message" => {
          "id" => chat_message.id,
          "content" => chat_message.content,
          "user" => {
            "id" => chat_message.user_id,
            "avatar_url" => nil,
            "display_name" => "John D."
          },
          "created_at" => chat_message.created_at.iso8601(3),
          "post_id" => nil,
          "has_comments" => false,
          "comments_count" => 0,
          "image_url" => nil,
          "read" => false,
          "message_type" => "text",
          "status" => "active"
        }
      }) }
    end

    context 'no deeplink' do
      before { get :show, params: { token: user.token, outing_id: outing.to_param, id: chat_message.id } }

      it { expect(response.status).to eq 200 }
      it { expect(result).to have_key("chat_message") }
      it { expect(result['chat_message']['id']).to eq(chat_message.id) }
    end

    context 'deeplink' do
      context 'using uuid_v2' do
        before { get :show, params: { token: user.token, outing_id: outing.uuid_v2, id: chat_message.uuid_v2, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_message') }
        it { expect(result['chat_message']['id']).to eq(chat_message.id) }
      end

      context 'using id fails' do
        before { get :show, params: { token: user.token, outing_id: outing.to_param, id: chat_message.id, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
    end
  end

  describe 'POST create' do
    before { Timecop.freeze }

    context "not signed in" do
      before { post :create, params: { outing_id: outing.to_param, chat_message: { content: "foobar"} } }

      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context "signed in but not in outing" do
      before { post :create, params: {
        outing_id: outing.to_param, chat_message: { content: "foobar", message_type: :text }, token: user.token
      } }

      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:ios_app) { FactoryBot.create(:ios_app, name: 'outing') }
      let!(:android_app) { FactoryBot.create(:android_app, name: 'outing') }

      context "nested chat_messages" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }
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
            "message_type" => "text",
            "status" => "active"
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
            token: user.token, outing_id: outing.to_param, chat_message: chat_message_params
          }
        }

        context "no nested" do
          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to eq(json) }
          # create does not update last_message_read
          it { expect(join_request.reload.last_message_read).to eq(nil) }
        end

        context "with nested" do
          let!(:chat_message) { FactoryBot.create(:chat_message, messageable: outing) }
          let(:parent_id) { chat_message.id }

          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(2) }
          it { expect(result).to eq(json) }
          # create does not update last_message_read
          it { expect(join_request.reload.last_message_read).to eq(nil) }
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
          join_request1 = FactoryBot.create(:join_request, joinable: outing, user: outing.user, status: :accepted)
          join_request2 = FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted)
          join_request3 = FactoryBot.create(:join_request, joinable: outing, status: :accepted)

          FactoryBot.create(:join_request, joinable: outing, status: "pending")

          expect_any_instance_of(PushNotificationService).to receive(:send_notification)

          post :create, params: { outing_id: outing.to_param, chat_message: { content: "foobaz" }, token: user.token }
        end
      end
    end
  end

  describe 'PATCH update' do
    let(:chat_message) { create :chat_message, messageable: outing, content: "bar", image_url: "foo" }

    context "not signed in" do
      before { patch :update, params: { id: chat_message.id, outing_id: outing.id, chat_message: { content: "new content" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      before { patch :update, params: { id: chat_message.id, outing_id: outing.id, chat_message: { content: "new content" } } }

      context "user is not creator" do
        before { patch :update, params: { id: chat_message.id, outing_id: outing.id, chat_message: { content: "new content" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        before { patch :update, params: { id: chat_message.id, outing_id: outing.id, chat_message: {
          content: "new content",
        }, token: chat_message.user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(result["chat_message"]["content"]).to eq("new content") }
        it { expect(result["chat_message"]["status"]).to eq("updated") }
      end
    end
  end

  describe 'DELETE destroy' do
    let(:chat_message) { create :chat_message, messageable: outing, content: "bar", image_url: "foo" }
    let(:result) { ChatMessage.find(chat_message.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: chat_message.id, outing_id: outing.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: chat_message.id, outing_id: outing.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'authorized' do
      before { delete :destroy, params: { id: chat_message.id, outing_id: outing.id, token: chat_message.user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.content).to be_nil }
      it { expect(result.status).to eq 'deleted' }
      it { expect(result.deleter_id).to eq(chat_message.user_id) }
      it { expect(result.deleted_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  describe 'POST #report' do
    let(:outing) { create :outing }
    let(:chat_message) { create :chat_message, messageable: outing }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: "accepted") }

    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "correct messageable" do
      before {
        expect_any_instance_of(SlackServices::SignalOutingChatMessage).to receive(:notify)
        post :report, params: { token: user.token, outing_id: outing.id, chat_message_id: chat_message.id, report: {
          signals: ['foo'],
          message: 'bar'
        } }
      }
      it { expect(response.status).to eq 201 }
    end

    context "wrong messageable cause no report signals" do
      before {
        expect_any_instance_of(SlackServices::SignalOutingChatMessage).not_to receive(:notify)
        post :report, params: { token: user.token, outing_id: outing.id, chat_message_id: chat_message.id, report: {
          message: 'bar'
        } }
      }
      it { expect(response.status).to eq 400 }
    end

    context "wrong messageable cause message does not belong to outing" do
      let(:entourage) { create :entourage }
      let(:entourage_chat_message) { create :chat_message, messageable: entourage }

      before {
        expect_any_instance_of(SlackServices::SignalOutingChatMessage).not_to receive(:notify)
        post :report, params: { token: user.token, outing_id: outing.id, chat_message_id: entourage_chat_message.id }
      }
      it { expect(response.status).to eq 400 }
    end
  end

  describe 'GET comments' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: outing, user: user) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: outing, user: user, parent: chat_message_1) }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }

    let(:request) { get :comments, params: { outing_id: outing.to_param, id: chat_message_1.id, token: user.token } }

    context "signed and in outing" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to eq({
        "chat_messages" => [{
          "id" => chat_message_2.id,
          "content" => chat_message_2.content,
          "user" => {
            "id" => user.id,
            "avatar_url" => nil,
            "display_name" => "John D."
          },
          "created_at" => chat_message_2.created_at.iso8601(3),
          "post_id" => chat_message_1.id,
          "has_comments" => false,
          "comments_count" => 0,
          "image_url" => nil,
          "read" => false,
          "message_type" => "text",
          "status" => "active"
        }]
      }) }
    end

    context "ordered" do
      let!(:chat_message_3) { FactoryBot.create(:chat_message, messageable: outing, user: user, parent: chat_message_1, created_at: chat_message_2.created_at + day) }

      before { request }

      context "in one order" do
        let(:day) { - 1.day }

        it { expect(result["chat_messages"].count).to eq(2) }
        it { expect(result["chat_messages"][0]["id"]).to eq(chat_message_3.id) }
        it { expect(result["chat_messages"][1]["id"]).to eq(chat_message_2.id) }
      end

      context "in another order" do
        let(:day) { + 1.day }

        it { expect(result["chat_messages"].count).to eq(2) }
        it { expect(result["chat_messages"][0]["id"]).to eq(chat_message_2.id) }
        it { expect(result["chat_messages"][1]["id"]).to eq(chat_message_3.id) }
      end
    end
  end

  describe 'POST #presigned_upload' do
    let(:request) { post :presigned_upload, params: { outing_id: outing.to_param, token: token, content_type: 'image/jpeg' } }

    context "not signed in" do
      let(:token) { nil }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in but not in outing" do
      let(:token) { user.token }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context "signed in and in outing" do
      let(:token) { user.token }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('upload_key') }
      it { expect(JSON.parse(response.body)).to have_key('presigned_url') }
    end
  end
end
