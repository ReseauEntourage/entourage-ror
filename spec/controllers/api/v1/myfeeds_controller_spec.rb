require 'rails_helper'
include CommunityHelper

describe Api::V1::MyfeedsController do

  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context 'not signed in' do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      let(:user) { FactoryBot.create(:pro_user) }
      let!(:entourage) { FactoryBot.create(:entourage, created_at: 4.hours.ago, entourage_type: 'ask_for_help') }

      context "get entourages i'm not part of" do
        before { get :index, params: { token: user.token } }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({'feeds'=>[], 'unread_count' => 0}) }
      end

      context 'get my entourages' do
        let!(:entourage_i_created) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago) }
        let!(:entourage_i_joined) { FactoryBot.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago) }
        let!(:entourage_i_canceled) { FactoryBot.create(:entourage, updated_at: 4.hour.ago) }
        let!(:entourage_i_canceled_join_request) { FactoryBot.create(:join_request, joinable: entourage_i_canceled, user: user, status: JoinRequest::CANCELLED_STATUS) }
        let!(:entourage) { FactoryBot.create(:entourage, :joined, join_request_user: FactoryBot.create(:public_user), updated_at: 3.hour.ago) }
        before { get :index, params: { token: user.token, status: 'open' } }
        it { expect(result['feeds'].map {|feed| feed['data']['id']} ).to eq([entourage_i_created.id, entourage_i_joined.id]) }
      end

      context "last_message i'm creator" do
        let!(:entourage) { create :entourage, :joined, user: user }

        context 'has join_request and messages' do
          context 'requests more recent that join messages' do
            let!(:join_request) { create :join_request, joinable: entourage, created_at: 1.minute.ago }
            let!(:chat_message) { create :chat_message, messageable: entourage, created_at: 2.minutes.ago }
            before { get :index, params: { token: user.token } }
            it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([{
              'text'=>'MyText',
              'author'=> {
                'first_name' => 'John',
                'last_name' => 'D',
                'display_name' => 'John D.',
                'id' => chat_message.user_id
              }
            }]) }
          end
        end
      end

      context "last_message i'm accepted in" do
        let(:other_user) { create :public_user }
        let!(:entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: other_user, created_at: 1.hour.ago) }

        context 'has messages' do
          let!(:chat_message1) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse('25/01/2000'), updated_at: DateTime.parse('25/01/2000'), content: 'foo') }
          let!(:chat_message2) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse('24/01/2000'), updated_at: DateTime.parse('24/01/2000'), content: 'bar') }
          before { get :index, params: { token: user.token } }
          it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([
            {'text'=>'foo',      'author'=>{'first_name'=>'John', 'last_name'=>'D', 'display_name'=>'John D.', 'id'=>chat_message1.user_id}}
          ]) }
        end

        context 'has no messages' do
          before { get :index, params: { token: user.token } }
          it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([nil]) }
        end

        context 'has join_request is not a last_message' do
          let!(:join_request) do
            entourage.join_requests.last.update(message: 'foo_bar')
          end
          before { get :index, params: { token: user.token } }
          it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([nil]) }
        end

        context 'has join_request and messages' do
          context 'messages more recent that join requests' do
            let!(:join_request) do
              entourage.join_requests.last.update(message: 'foo_bar', created_at: DateTime.parse('10/01/2015'), updated_at: DateTime.parse('10/01/2015'))
            end
            let!(:chat_message1) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse('10/01/2016'), updated_at: DateTime.parse('10/01/2016'), content: 'foo') }
            before { get :index, params: { token: user.token } }
            it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([{
              'text'=>'foo',
              'author'=> {
                'first_name' => 'John',
                'last_name' => 'D',
                'display_name' => 'John D.',
                'id' => chat_message1.user_id
              }
            }]) }
          end

          context 'join requests more recent that messages' do
            let!(:join_request) do
              entourage.join_requests.last.update(message: 'foo_bar', created_at: DateTime.parse('10/01/2016'), updated_at: DateTime.parse('10/01/2016'))
            end
            let!(:chat_message1) { FactoryBot.create(:chat_message, messageable: entourage, created_at: DateTime.parse('10/01/2015'), updated_at: DateTime.parse('10/01/2015'), content: 'foo') }
            before { get :index, params: { token: user.token } }
            it { expect(result['feeds'].map {|feed| feed['data']['last_message']} ).to eq([{
              'text'=>'foo',
              'author'=> {
                'first_name' => 'John',
                'last_name' => 'D',
                'display_name' => 'John D.',
                'id' => chat_message1.user_id
              }
            }]) }
          end
        end
      end

      context 'filter by status' do
        let!(:entourage_open) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, status: :open) }
        let!(:entourage_closed) { FactoryBot.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago, status: :closed) }
        let!(:entourage_blacklisted) { FactoryBot.create(:entourage, :joined, join_request_user: user, updated_at: 3.hour.ago, status: :blacklisted) }
        let!(:entourage_suspended_by_other) { FactoryBot.create(:entourage, :joined, join_request_user: user, updated_at: 4.hour.ago, status: :suspended) }
        let!(:entourage_suspended_by_me) { FactoryBot.create(:entourage, :joined, user: user, updated_at: 5.hour.ago, status: :suspended) }

        context 'get default feeds' do
          before { get :index, params: { token: user.token } }
          it { expect(result['feeds'].map {|feed| feed['data']['id']} ).to eq([entourage_open.id, entourage_closed.id, entourage_suspended_by_me.id]) }
        end
      end

      context 'community entourage' do
        let!(:entourage) { nil }
        let!(:conversation) { create :conversation, participants: [user] }
        before { get :index, params: { token: user.token, status: 'open' } }
        it { expect(result['feeds'].map {|feed| feed['data']['uuid']}.sort).to eq([conversation.uuid_v2].sort) }
      end
    end

    context 'unread tab' do
      let(:user) { create :public_user }
      let(:action_creator) { create :public_user }
      let(:entourage) { create :entourage, user: action_creator, feed_updated_at: feed_updated_at }
      let(:join_status) { :accepted }
      let!(:join_request) { create :join_request, user: user, joinable: entourage, status: join_status, last_message_read: last_message_read }

      let(:feed_objects) do
        get :index, params: { token: user.token, unread_only: true }
        result['feeds'].map { |f| [f['type'], f['data']['id']]}
      end

      context 'member of the group' do
        context 'read' do
          let(:feed_updated_at) { 1.hour.ago }
          let(:last_message_read) { 1.minute.ago }

          it { expect(feed_objects).to eq [] }
        end

        context 'unread' do
          let(:feed_updated_at) { 1.minute.ago }
          let(:last_message_read) { 1.hour.ago }

          it { expect(feed_objects).to eq [['Entourage', entourage.id]] }
        end
      end

      context 'unread but pending' do
        let(:join_status) { :pending }
        let(:feed_updated_at) { 1.minute.ago }
        let(:last_message_read) { 1.hour.ago }

        it { expect(feed_objects).to eq [] }
      end

      context 'read but user is creator and join request pending' do
        let(:action_creator) { user }
        let(:feed_updated_at) { 1.hour.ago }
        let(:last_message_read) { 1.minute.ago }
        let!(:pending_join_request) { create :join_request, joinable: entourage, status: :pending }

        it { expect(feed_objects).to eq [['Entourage', entourage.id]] }
      end
    end
  end
end
