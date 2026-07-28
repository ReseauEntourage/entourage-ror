require 'rails_helper'
include AuthHelper

describe Admin::ChatMessagesController do
  render_views

  let!(:admin) { admin_basic_login }

  describe 'GET #show' do
    let!(:chat_message) { create(:chat_message, content: 'foo') }

    before { get :show, params: { id: chat_message.id }, format: :js, xhr: true }

    it { expect(response).to be_successful }
    it { expect(assigns(:chat_message)).to eq(chat_message) }
    it { expect(response.body).to include("chat_message_content_edit_#{chat_message.id}") }
  end

  describe 'PATCH #update' do
    let!(:chat_message) { create(:chat_message, content: 'foo') }
    let(:new_content) { '<p>Bonjour <strong>tout le monde</strong></p><ul><li>un</li></ul>' }

    before { patch :update, params: { id: chat_message.id, chat_message: { content: new_content } }, format: :js }

    it { expect(response).to be_successful }
    it { expect(chat_message.reload.content).to include('<strong>tout le monde</strong>') }
    it { expect(chat_message.reload.content).to include('<li>un</li>') }

    context 'with a script tag (not part of the allowed rich text tags)' do
      let(:new_content) { '<p>Bonjour</p><script>alert(1)</script>' }

      it { expect(chat_message.reload.content).not_to include('<script>') }
      it { expect(chat_message.reload.content).to include('alert(1)') }
    end
  end

  describe 'GET #cancel_update' do
    let!(:chat_message) { create(:chat_message, content: 'foo') }

    before { get :cancel_update, params: { id: chat_message.id }, format: :js, xhr: true }

    it { expect(response).to be_successful }
    it { expect(chat_message.reload.content).to eq('foo') }
  end
end
