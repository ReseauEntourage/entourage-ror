require 'rails_helper'

RSpec.describe Event, type: :model do
  let!(:user) { create(:user) }

  describe '.track' do
    before do
      allow(Rails.logger).to receive(:warn)
    end

    context 'when everything is valid' do
      it 'creates an event in database' do
        expect {
          Event.track('onboarding.resource.welcome_watched', user_id: user.id)
        }.to change(Event, :count).by(1)

        event = Event.order(created_at: :desc).first
        expect(event.name).to eq('onboarding.resource.welcome_watched')
        expect(event.user_id).to eq(user.id)
      end
    end

    context 'when event name is invalid (not in enum)' do
      let(:subject) { Event.track('invalid.event.name', user_id: user.id) }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to change(Event, :count).by(0) }
    end

    context 'when user_id is nil' do
      let(:subject) { Event.track('onboarding.resource.welcome_watched', user_id: nil) }

      it { expect { subject }.not_to raise_error }
      it { expect { subject }.to change(Event, :count).by(0) }
    end
  end

  describe '.valid_event_name?' do
    it 'returns true for a valid enum value' do
      expect(
        Event.valid_event_name?('onboarding.resource.welcome_watched')
      ).to be true
    end

    it 'returns false for an invalid value' do
      expect(
        Event.valid_event_name?('totally.invalid.event')
      ).to be false
    end
  end

  describe '.valid_event_names' do
    it 'returns all enum values' do
      names = Event.valid_event_names

      expect(names).to be_an(Array)
      expect(names).to include('onboarding.resource.welcome_watched')
    end

    it 'memoizes the result' do
      first_call = Event.valid_event_names
      second_call = Event.valid_event_names

      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end
end
