require 'rails_helper'

describe Api::V1::JulesController do
  describe 'POST #create' do
    context 'url_verification' do
      let(:params) { {
        type: 'url_verification',
        challenge: 'challenge-token'
      } }

      before { post :create, params: params }

      it { expect(response.status).to eq(200) }
      it { expect(JSON.parse(response.body)).to eq({ 'challenge' => 'challenge-token' }) }
    end

    context 'event_callback' do
      let(:params) { {
        type: 'event_callback',
        event: {
          type: 'app_mention',
          channel: 'C12345',
          ts: '123456.789',
          text: '<@U12345> what are the outing filters?',
          user: 'U67890'
        }
      } }

      it 'enqueues SlackQuestionJob' do
        expect {
          post :create, params: params
        }.to have_enqueued_job(SlackQuestionJob).with(
          channel: 'C12345',
          ts: '123456.789',
          text: '<@U12345> what are the outing filters?',
          user: 'U67890'
        )
      end

      it 'returns 200' do
        post :create, params: params
        expect(response.status).to eq(200)
      end
    end
  end
end
