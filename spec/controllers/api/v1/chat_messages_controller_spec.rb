require 'rails_helper'

describe Api::V1::ChatMessagesController do
  let(:user) { FactoryBot.create(:pro_user) }

  let(:result) { JSON.parse(response.body) }

  describe 'DELETE destroy' do
    let!(:chat_message) { create :chat_message, content: "bar", image_url: "foo" }
    let(:result) { ChatMessage.find(chat_message.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: chat_message.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: chat_message.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'active' }
    end

    describe 'authorized' do
      before { delete :destroy, params: { id: chat_message.id, token: chat_message.user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.content).to be_nil }
      it { expect(result.status).to eq 'deleted' }
      it { expect(result.deleter_id).to eq(chat_message.user_id) }
      it { expect(result.deleted_at).to be_a(ActiveSupport::TimeWithZone) }
    end
  end
end
