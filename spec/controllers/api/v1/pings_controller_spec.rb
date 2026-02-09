require 'rails_helper'

RSpec.describe Api::V1::PingsController, type: :controller do
  describe 'POST dispatch_websocket' do
    it 'broadcasts a message' do
      expect {
        post :dispatch_websocket, params: { message: 'Test message' }
      }.to have_broadcasted_to('ping_channel').with(message: 'Test message')

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['status']).to eq('Message broadcasted')
    end

    it 'broadcasts a default message if none provided' do
      expect {
        post :dispatch_websocket
      }.to have_broadcasted_to('ping_channel')

      expect(response.status).to eq(200)
    end
  end
end
