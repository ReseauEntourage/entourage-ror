require 'rails_helper'

RSpec.describe Api::V1::PingsController, type: :controller do
  include ActionCable::TestHelper

  describe 'POST dispatch_websocket' do
    it 'broadcasts a message to ping_channel' do
      expect {
        post :dispatch_websocket, params: { message: 'Success' }
      }.to have_broadcasted_to('ping_channel').with(message: 'Success')

      expect(response).to have_http_status(:success)
    end
  end
end
