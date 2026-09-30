require 'rails_helper'

describe Meeting do
  describe '#create_google_meet_event' do
    # created before stubbing the authorization, so that after_create does not reach the Meet API
    let!(:meeting) { create :meeting, meet_link: nil }
    let(:authorization) { double('authorization', access_token: 'fresh_token') }
    let(:space) { { name: 'spaces/abc', meetingUri: 'https://meet.google.com/abc-defg-hij' } }

    let!(:meet_request) {
      stub_request(:post, 'https://meet.googleapis.com/v2/spaces')
        .with(headers: { 'Authorization' => 'Bearer fresh_token' })
        .to_return(status: 200, body: space.to_json)
    }

    before do
      allow(GOOGLE_CALENDAR_SERVICE).to receive(:authorization).and_return(authorization)
      allow(authorization).to receive(:needs_access_token?).and_return(needs_access_token)
      allow(authorization).to receive(:fetch_access_token!)
    end

    subject { meeting.create_google_meet_event }

    context 'when the access token has expired' do
      let(:needs_access_token) { true }

      it 'refreshes it before calling the Meet API' do
        expect(authorization).to receive(:fetch_access_token!)
        subject
        expect(meet_request).to have_been_requested.at_least_once
      end

      it { expect { subject }.to change { meeting.reload.meet_link }.to(space[:meetingUri]) }
    end

    context 'when the access token is still valid' do
      let(:needs_access_token) { false }

      it 'does not refresh it' do
        expect(authorization).not_to receive(:fetch_access_token!)
        subject
      end
    end
  end
end
