require 'rails_helper'

RSpec.describe Api::V1::PingsController, type: :controller do
  describe 'POST dispatch_websocket' do
    it 'broadcasts a message to ping_channel' do
      expect {
        post :dispatch_websocket, params: { message: 'Test Message' }
      }.to have_broadcasted_to('ping_channel').with(message: 'Test Message')

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['status']).to eq('Message broadcasted')
    end

    it 'broadcasts a default message if none provided' do
      expect {
        post :dispatch_websocket
      }.to have_broadcasted_to('ping_channel')

      expect(response).to have_http_status(:success)
    end
  end
end
