require 'rails_helper'
include AuthHelper

describe Admin::ChatMessagesController do
  let!(:admin) { admin_basic_login }
  let!(:chat_message) { FactoryBot.create(:chat_message, content: 'hello') }

  describe 'PUT update_video' do
    context 'with a valid youtube embed url' do
      before {
        put :update_video, params: { id: chat_message.id, chat_message: { video_url: 'https://www.youtube.com/embed/abc123' } }, format: :js
      }

      it { expect(chat_message.reload.video_url).to eq('https://www.youtube.com/embed/abc123') }
    end

    context 'with an invalid url' do
      before {
        put :update_video, params: { id: chat_message.id, chat_message: { video_url: 'https://vimeo.com/123' } }, format: :js
      }

      it { expect(chat_message.reload.video_url).to be_nil }
      it { expect(response).to be_successful }
    end
  end

  describe 'DELETE delete_video' do
    let!(:chat_message) { FactoryBot.create(:chat_message, content: 'hello', video_url: 'https://www.youtube.com/embed/abc123') }

    before { delete :delete_video, params: { id: chat_message.id }, format: :js }

    it { expect(chat_message.reload.video_url).to be_nil }
  end
end
