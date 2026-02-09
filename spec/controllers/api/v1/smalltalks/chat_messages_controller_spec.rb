require 'rails_helper'

describe Api::V1::Smalltalks::ChatMessagesController do
  let(:user) { create(:pro_user) }

  let(:smalltalk) { create :smalltalk }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:chat_message_1) { create(:chat_message, messageable: smalltalk, user: user, created_at: 1.hour.ago) }
    let!(:chat_message_2) { create(:chat_message, messageable: smalltalk, user: user) }

    before { Timecop.freeze }
    before { ChatMessage.stub(:url_for_with_size) { 'http://foo.bar'} }

    context 'not signed in' do
      before { get :index, params: { smalltalk_id: smalltalk.to_param } }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in but not in smalltalk' do
      before { get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
    end

    context 'signed and in smalltalk' do
      let!(:join_request) { create(:join_request, joinable: smalltalk, user: user, status: :accepted) }

      before { get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to match_array({
        'chat_messages' => [{
          'id' => chat_message_1.id,
          'uuid_v2' => chat_message_1.uuid_v2,
          'content' => chat_message_1.content,
          'content_html' => chat_message_1.content,
          'content_translations' => {
            'translation' => chat_message_1.content,
            'original' => chat_message_1.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'content_translations_html' => {
            'translation' => chat_message_1.content,
            'original' => chat_message_1.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'user' => {
            'id' => user.id,
            'avatar_url' => nil,
            'display_name' => 'John D.',
            'partner' => nil,
            'partner_role_title' => nil,
            'birthday_today' => be_boolean,
            'roles' => []
          },
          'created_at' => chat_message_1.created_at.iso8601(3),
          'post_id' => nil,
          'has_comments' => false,
          'comments_count' => 0,
          'image_url' => nil,
          'read' => false,
          'message_type' => 'text',
          'status' => 'active',
          'survey' => nil
        }, {
          'id' => chat_message_2.id,
          'uuid_v2' => chat_message_2.uuid_v2,
          'content' => chat_message_2.content,
          'content_html' => chat_message_2.content,
          'content_translations' => {
            'translation' => chat_message_2.content,
            'original' => chat_message_2.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'content_translations_html' => {
            'translation' => chat_message_2.content,
            'original' => chat_message_2.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'user' => {
            'id' => user.id,
            'avatar_url' => nil,
            'display_name' => 'John D.',
            'partner' => nil,
            'partner_role_title' => nil,
            'birthday_today' => be_boolean,
            'roles' => []
          },
          'created_at' => chat_message_2.created_at.iso8601(3),
          'post_id' => nil,
          'has_comments' => false,
          'comments_count' => 0,
          'image_url' => nil,
          'read' => false,
          'message_type' => 'text',
          'status' => 'active',
          'survey' => nil
        }]
      }) }
    end

    context 'chat_message read and last_message_read' do
      let(:last_message_read) { join_request.reload.last_message_read.to_s }
      let(:time) { Time.now }
      let!(:join_request) { create(:join_request, joinable: smalltalk, user: user, status: :accepted, last_message_read: time) }

      before { get :index, params: { smalltalk_id: smalltalk.to_param, token: user.token } }

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

    describe 'no deeplink' do
      before { get :index, params: { smalltalk_id: identifier, token: user.token } }

      context 'from id' do
        let(:identifier) { smalltalk.id }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_1.id) }
      end

      context 'from uuid_v2' do
        let(:identifier) { smalltalk.uuid_v2 }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_1.id) }
      end
    end

    context 'deeplink' do
      context 'using uuid_v2' do
        before { get :index, params: { smalltalk_id: smalltalk.uuid_v2, token: user.token, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_1.id) }
      end

      context 'using id fails' do
        before { get :index, params: { smalltalk_id: smalltalk.id, token: user.token, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
    end
  end

  describe 'POST create' do
    before { Timecop.freeze }

    context 'not signed in' do
      before { post :create, params: { smalltalk_id: smalltalk.to_param, chat_message: { content: 'foobar'} } }

      it { expect(response.status).to eq(401) }
      it { expect(ChatMessage.count).to eq(0) }
    end

    context 'signed in but not in smalltalk' do
      before { post :create, params: {
        smalltalk_id: smalltalk.to_param, chat_message: { content: 'foobar', message_type: :text }, token: user.token
      } }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      let!(:ios_app) { create(:ios_app, name: 'smalltalk') }
      let!(:android_app) { create(:android_app, name: 'smalltalk') }

      context 'nested chat_messages' do
        let!(:join_request) { create(:join_request, joinable: smalltalk, user: user, status: :accepted) }
        let(:content) { 'foobar' }
        let(:image_url) { nil }
        let(:parent_id) { nil }
        let(:has_comments) { false }

        let(:json) {{
          'chat_message' => {
            'id' => ChatMessage.last.id,
            'uuid_v2' => ChatMessage.last.uuid_v2,
            'content' => content,
            'content_html' => content,
            'content_translations' => {
              'translation' => content,
              'original' => content,
              'from_lang' => 'fr',
              'to_lang' => 'fr',
            },
            'content_translations_html' => {
              'translation' => content,
              'original' => content,
              'from_lang' => 'fr',
              'to_lang' => 'fr',
            },
            'user' => {
              'id' => user.id,
              'avatar_url' => nil,
              'display_name' => 'John D.',
              'partner' => nil,
              'partner_role_title' => nil,
              'birthday_today' => be_boolean,
              'roles' => []
            },
            'created_at' => ChatMessage.last.created_at.iso8601(3),
            'post_id' => parent_id,
            'has_comments' => has_comments,
            'comments_count' => 0,
            'image_url' => image_url,
            'read' => nil,
            'message_type' => 'text',
            'status' => 'active',
            'survey' => nil
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
            token: user.token, smalltalk_id: smalltalk.to_param, chat_message: chat_message_params
          }
        }

        context 'no nested' do
          it { expect(response.status).to eq(201) }
          it { expect(ChatMessage.count).to eq(1) }
          it { expect(result).to match_array(json) }
          # create does update last_message_read in ChatServices::ChatMessageBuilder
          it { expect(join_request.reload.last_message_read).to be_a(ActiveSupport::TimeWithZone) }
        end
      end

      describe 'send push notif' do
        it 'sends notif to everyone accepted except message sender' do
          join_request = create(:join_request, joinable: smalltalk, user: user, status: :accepted)
          join_request2 = create(:join_request, joinable: smalltalk, status: :accepted)

          create(:join_request, joinable: smalltalk, status: 'pending')

          expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
            nil,
            PushNotificationTrigger::I18nStruct.new(i18n: 'activerecord.attributes.smalltalk.object'),
            PushNotificationTrigger::I18nStruct.new(instance: kind_of(ChatMessage), field: :content),
            [ join_request2.user ],
            'smalltalk',
            smalltalk.id,
            {
              tracking: :post_on_create_to_smalltalk,
              joinable_id: smalltalk.id,
              joinable_type: 'Smalltalk',
              group_type: 'smalltalk',
              type: 'NEW_CHAT_MESSAGE',
              instance: 'smalltalk',
              instance_id: smalltalk.id
            }
          )

          post :create, params: { smalltalk_id: smalltalk.to_param, chat_message: { content: 'foobaz' }, token: user.token }
        end
      end
    end
  end

  describe 'PATCH update' do
    let(:chat_message) { create :chat_message, messageable: smalltalk, content: 'bar', image_url: 'foo' }

    context 'not signed in' do
      before { patch :update, params: { id: chat_message.id, smalltalk_id: smalltalk.id, chat_message: { content: 'new content' } } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { patch :update, params: { id: chat_message.id, smalltalk_id: smalltalk.id, chat_message: { content: 'new content' } } }

      context 'user is not creator' do
        before { patch :update, params: { id: chat_message.id, smalltalk_id: smalltalk.id, chat_message: { content: 'new content' }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context 'user is creator' do
        before { patch :update, params: { id: chat_message.id, smalltalk_id: smalltalk.id, chat_message: {
          content: 'new content',
        }, token: chat_message.user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(result['chat_message']['content']).to eq('new content') }
        it { expect(result['chat_message']['status']).to eq('updated') }
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:chat_message) { create :chat_message, messageable: smalltalk, content: 'bar', image_url: 'foo' }
    let(:result) { ChatMessage.find(chat_message.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: chat_message.id, smalltalk_id: smalltalk.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: chat_message.id, smalltalk_id: smalltalk.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'authorized' do
      before { delete :destroy, params: { id: chat_message.id, smalltalk_id: smalltalk.id, token: chat_message.user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.content).to eq('') }
      it { expect(result.status).to eq 'deleted' }
      it { expect(result.deleter_id).to eq(chat_message.user_id) }
      it { expect(result.deleted_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end

  describe 'GET comments' do
    let!(:chat_message_1) { FactoryBot.create(:chat_message, messageable: smalltalk, user: user) }
    let!(:chat_message_2) { FactoryBot.create(:chat_message, messageable: smalltalk, user: user, parent: chat_message_1) }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: smalltalk, user: user, status: :accepted) }

    let(:request) { get :comments, params: { smalltalk_id: smalltalk.to_param, id: chat_message_1.id, token: user.token } }

    context 'signed and in smalltalk' do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(result).to have_key('chat_messages')}
      it { expect(result).to match_array({
        'chat_messages' => [{
          'id' => chat_message_2.id,
          'uuid_v2' => chat_message_2.uuid_v2,
          'content' => chat_message_2.content,
          'content_html' => chat_message_2.content,
          'content_translations' => {
            'translation' => chat_message_2.content,
            'original' => chat_message_2.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'content_translations_html' => {
            'translation' => chat_message_2.content,
            'original' => chat_message_2.content,
            'from_lang' => 'fr',
            'to_lang' => 'fr',
          },
          'user' => {
            'id' => user.id,
            'avatar_url' => nil,
            'display_name' => 'John D.',
            'partner' => nil,
            'partner_role_title' => nil,
            'birthday_today' => be_boolean,
            'roles' => []
          },
          'created_at' => chat_message_2.created_at.iso8601(3),
          'post_id' => chat_message_1.id,
          'has_comments' => false,
          'comments_count' => 0,
          'image_url' => nil,
          'read' => false,
          'message_type' => 'text',
          'status' => 'active',
          'survey' => nil,
        }]
      }) }
    end

    context 'ordered' do
      let!(:chat_message_3) { FactoryBot.create(:chat_message, messageable: smalltalk, user: user, parent: chat_message_1, created_at: chat_message_2.created_at + day) }

      before { request }

      context 'in one order' do
        let(:day) { - 1.day }

        it { expect(result['chat_messages'].count).to eq(2) }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_3.id) }
        it { expect(result['chat_messages'][1]['id']).to eq(chat_message_2.id) }
      end

      context 'in another order' do
        let(:day) { + 1.day }

        it { expect(result['chat_messages'].count).to eq(2) }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_2.id) }
        it { expect(result['chat_messages'][1]['id']).to eq(chat_message_3.id) }
      end
    end

    describe 'no deeplink' do
      before { get :comments, params: { token: user.token, smalltalk_id: identifier, id: chat_message_1.id } }

      context 'from id' do
        let(:identifier) { smalltalk.id }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_2.id) }
      end

      context 'from uuid_v2' do
        let(:identifier) { smalltalk.uuid_v2 }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_2.id) }
      end
    end

    context 'deeplink' do
      context 'using uuid_v2' do
        before { get :comments, params: { token: user.token, smalltalk_id: smalltalk.uuid_v2, id: chat_message_1.uuid_v2, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(result).to have_key('chat_messages') }
        it { expect(result['chat_messages'][0]['id']).to eq(chat_message_2.id) }
      end

      context 'using id fails' do
        before { get :comments, params: { token: user.token, smalltalk_id: smalltalk.to_param, id: chat_message_1.id, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
    end
  end

  describe 'POST #presigned_upload' do
    let(:request) { post :presigned_upload, params: { smalltalk_id: smalltalk.to_param, token: token, content_type: 'image/jpeg' } }

    context 'not signed in' do
      let(:token) { nil }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in but not in smalltalk' do
      let(:token) { user.token }

      before { request }

      it { expect(response.status).to eq(401) }
    end

    context 'signed in and in smalltalk' do
      let(:token) { user.token }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: smalltalk, user: user, status: :accepted) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to have_key('upload_key') }
      it { expect(JSON.parse(response.body)).to have_key('presigned_url') }
    end
  end
end
