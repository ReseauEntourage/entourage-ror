require 'rails_helper'
include CommunityHelper

describe Api::V1::ConversationsController do
  let(:user) { FactoryBot.create(:public_user) }
  before { ModerationServices.stub(:moderator) { nil } }

  describe 'GET index' do
    subject { JSON.parse(response.body)["conversations"] }

    let(:request) { get :index, params: { token: user.token }}
    let(:participant) { create :public_user, first_name: :Jane }

    context 'conversations and actions' do
      let(:conversation) { create :conversation, participants: [user, participant] }
      let(:action) { create :entourage, status: :open, group_type: :action, participants: [user] }
      let(:outing) { create :outing, status: :open, participants: [user] }

      let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: conversation)}
      let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: action)}
      let!(:chat_message_3) { FactoryBot.create(:chat_message, messageable: outing)}

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject.count).to eq(2) }
      it { expect(subject.map{|c| c["id"] }).to match_array([conversation.id, action.id]) }
    end

    context 'conversations of any status' do
      let(:conversation) { create :conversation, participants: [user, participant] }
      let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: conversation)}

      context 'open' do
        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(1) }
        it { expect(subject[0]["id"]).to eq(conversation.id) }
      end

      context 'closed' do
        let(:conversation) { create :conversation, participants: [user, participant], status: :closed }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(1) }
        it { expect(subject[0]["id"]).to eq(conversation.id) }
      end
    end

    context 'conversations as member' do
      let(:conversation) { create :conversation, participants: [participant] }
      let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation)}

      context 'is member' do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(1) }
        it { expect(subject[0]["id"]).to eq(conversation.id) }
      end

      context 'is not member' do
        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(0) }
      end

      context 'is not accepted member' do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :cancelled) }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(0) }
      end
    end

    context 'should return conversations having chat_messages' do
      let(:conversation) { create :conversation, participants: [participant] }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

      context 'having chat_messages' do
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation)}

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(1) }
        it { expect(subject[0]["id"]).to eq(conversation.id) }
      end

      context 'not having chat_messages' do
        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject.count).to eq(0) }
      end
    end
  end

  describe 'GET private' do
    let(:other_user) { FactoryBot.create(:public_user) }
    subject { JSON.parse(response.body) }

    context "no private conversations" do
      let!(:conversation) { create :conversation, participants: [other_user] }

      before { get :private, params: { token: user.token } }

      it { expect(subject["entourages"].count).to eq(0) }
    end

    context "actions are not private" do
      let(:entourage) { create :entourage, status: :open, group_type: :action }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }

      before { get :private, params: { token: user.token } }

      it { expect(subject["entourages"].count).to eq(0) }
    end

    describe "some private conversations" do
      let!(:conversation) { create :conversation, user: creator }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: "accepted", last_message_read: Time.now) }
      let!(:other_conversation) { create :conversation, participants: [other_user] }

      let(:creator) { user }

      context "title" do
        let!(:other_user) { FactoryBot.create :public_user, first_name: "foo", last_name: "bar" }
        let!(:other_user_join_request) { FactoryBot.create(:join_request, joinable: conversation, user: other_user, status: "accepted", last_message_read: Time.now) }

        before { get :private, params: { token: user.token } }

        context "title is other participant name when the user is the creator" do
          # let(:creator) { user }
          it { expect(subject["entourages"].count).to eq(1) }
          it { expect(subject["entourages"][0]["title"]).to eq("Foo B.") }
        end

        context "title is other participant name when the user is not the creator" do
          let(:creator) { other_user }
          it { expect(subject["entourages"].count).to eq(1) }
          it { expect(subject["entourages"][0]["title"]).to eq("Foo B.") }
        end
      end

      context "default properties" do
        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]).to have_key("last_message") }
        it { expect(subject["entourages"][0]).to have_key("number_of_unread_messages") }
      end

      context "with unread" do
        let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.from_now, messageable: conversation)}

        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].first["number_of_unread_messages"]).to eq(1) }
      end

      context "without unread" do
        let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.ago, messageable: conversation)}

        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].first["number_of_unread_messages"]).to eq(0) }
      end

      context "with last_message" do
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: conversation)}

        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].first["last_message"]).to be_a(Hash) }
      end

      context "with some messages, get last_message" do
        let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: conversation, content: "foo", created_at: 1.hour.ago) }
        let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: conversation, content: "bar", created_at: 2.hours.ago) }

        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].first["last_message"]).to be_a(Hash) }
        it { expect(subject["entourages"].first["last_message"]["text"]).to eq("foo") }
      end

      context "without last_message" do
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: other_conversation)}

        before { get :private, params: { token: user.token } }
        it { expect(subject["entourages"].first["last_message"]).to eq(nil) }
      end
    end
  end

  describe 'GET group' do
    let!(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let!(:other_entourage) { FactoryBot.create(:entourage, status: :open) }
    let(:other_user) { FactoryBot.create(:public_user) }
    subject { JSON.parse(response.body) }

    describe "some group conversations" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted", last_message_read: Time.now) }

      context "default properties" do
        before { get :group, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]).to have_key("last_message") }
        it { expect(subject["entourages"][0]).to have_key("number_of_unread_messages") }
      end

      context "with unread" do
        let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.from_now, messageable: entourage)}

        before { get :group, params: { token: user.token } }
        it { expect(subject["entourages"].first["number_of_unread_messages"]).to eq(1) }
      end

      context "without unread" do
        let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.ago, messageable: entourage)}

        before { get :group, params: { token: user.token } }
        it { expect(subject["entourages"].first["number_of_unread_messages"]).to eq(0) }
      end

      context "with last_message" do
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: entourage)}

        before { get :group, params: { token: user.token } }
        it { expect(subject["entourages"].first["last_message"]).to be_a(Hash) }
      end

      context "without last_message" do
        let!(:chat_message) { FactoryBot.create(:chat_message, messageable: other_entourage)}

        before { get :group, params: { token: user.token } }
        it { expect(subject["entourages"].first["last_message"]).to eq(nil) }
      end
    end

    context "no group conversations" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: other_user, status: "accepted") }

      before { get :group, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end

    context "group conversations are not accepted" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "pending") }

      before { get :group, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end
  end

  describe 'GET metadata' do
    let!(:group) { FactoryBot.create(:entourage, status: :open) }
    let(:other_user) { FactoryBot.create(:public_user) }
    let!(:conversation) { create :conversation, participants: [other_user] }
    subject { JSON.parse(response.body) }

    describe "some metadata conversations" do
      context "group conversation" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: group, user: user, status: "accepted", last_message_read: Time.now) }

        before { get :metadata, params: { token: user.token } }
        it { expect(subject).to have_key("conversations") }
        it { expect(subject['conversations']['count']).to eq(0) }
        it { expect(subject['conversations']['unread']).to eq(0) }
        it { expect(subject).to have_key("actions") }
        it { expect(subject['actions']['count']).to eq(1) }
        it { expect(subject['actions']['unread']).to eq(0) }
      end

      context "private conversation" do
        let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: "accepted", last_message_read: Time.now) }

        before { get :metadata, params: { token: user.token } }
        it { expect(subject).to have_key("conversations") }
        it { expect(subject['conversations']['count']).to eq(1) }
        it { expect(subject).to have_key("actions") }
        it { expect(subject['actions']['count']).to eq(0) }
      end
    end
  end

  describe 'POST #report' do
    let(:conversation) { create :conversation }
    let(:params) { { token: user.token, id: conversation.id, report: { signals: signals, message: 'bar' } } }
    let(:signals) { ['foo'] }

    let!(:join_request) { FactoryBot.create(:join_request, joinable: conversation, user: user, status: :accepted) }

    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "valid params" do
      before {
        expect_any_instance_of(SlackServices::SignalConversation).to receive(:notify)
        post :report, params: params
      }

      it { expect(response.status).to eq 201 }
    end

    context "missing signals" do
      let(:signals) { [] }

      before {
        expect_any_instance_of(SlackServices::SignalConversation).not_to receive(:notify)
        post :report, params: params
      }

      it { expect(response.status).to eq 400 }
    end

    context "user is not member" do
      let!(:join_request) { nil }

      before {
        expect_any_instance_of(SlackServices::SignalConversation).not_to receive(:notify)
        post :report, params: params
      }

      it { expect(response.status).to eq 401 }
    end
  end
end
