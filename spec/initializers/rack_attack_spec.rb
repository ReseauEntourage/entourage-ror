require 'rails_helper'

RSpec.describe Rack::Attack, type: :request do
  include Rack::Test::Methods

  def app
    Rails.application
  end

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    # Mock Slack notification to avoid network calls
    allow_any_instance_of(SlackServices::SignalRackAttack).to receive(:notify).and_return(true)
  end

  describe 'Throttling API user creation' do
    context 'by IP' do
      it 'throttles after 5 requests in 1 minute' do
        5.times do
          post '/api/v1/users', { user: { phone: '+33600000001' } }
          expect(last_response.status).to eq(201).or eq(400) # 201 created or 400 if validation fails, but not 429
        end

        post '/api/v1/users', { user: { phone: '+33600000001' } }
        expect(last_response.status).to eq(429)
      end
    end

    context 'by phone' do
      it 'throttles after 2 requests in 5 minutes' do
        phone = '+33612345678'

        # Request 1 from IP 1
        post '/api/v1/users', { user: { phone: phone } }, 'REMOTE_ADDR' => '1.1.1.1'
        expect(last_response.status).to eq(201).or eq(400)

        # Request 2 from IP 2
        post '/api/v1/users', { user: { phone: phone } }, 'REMOTE_ADDR' => '1.1.1.2'
        expect(last_response.status).to eq(201).or eq(400)

        # Request 3 from IP 3
        post '/api/v1/users', { user: { phone: phone } }, 'REMOTE_ADDR' => '1.1.1.3'
        expect(last_response.status).to eq(429)
      end
    end
  end

  describe 'Throttling organization admin identification' do
    it 'throttles after 5 requests in 1 minute' do
      5.times do
        post '/organization_admin/session/identify', { phone: '+33600000001' }
        expect(last_response.status).not_to eq(429)
      end

      post '/organization_admin/session/identify', { phone: '+33600000001' }
      expect(last_response.status).to eq(429)
    end
  end

  describe 'Throttling entourage invitations' do
    it 'throttles after 10 requests in 1 minute' do
      entourage_id = 123
      10.times do
        post "/api/v1/entourages/#{entourage_id}/invitations", { invite: { mode: 'SMS', phone_numbers: ['+33600000001'] } }
        expect(last_response.status).not_to eq(429)
      end

      post "/api/v1/entourages/#{entourage_id}/invitations", { invite: { mode: 'SMS', phone_numbers: ['+33600000001'] } }
      expect(last_response.status).to eq(429)
    end
  end
end
