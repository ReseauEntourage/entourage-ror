require 'rails_helper'

RSpec.describe Api::V1::PingsController, type: :controller do
  include ActionCable::TestHelper

  describe 'POST dispatch_websocket' do
    it 'broadcasts a message to ping_channel' do
      expect {
        post :dispatch_websocket, params: { message: 'Hello from Test' }
      }.to have_broadcasted_to('ping_channel').with(message: 'Hello from Test')

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('Message broadcasted')
      expect(json['message']).to eq('Hello from Test')
    end
  end
end
