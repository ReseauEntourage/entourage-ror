require 'rails_helper'

describe Onboarding::UserEventsTracking do
  let!(:user) { create(:public_user) }

  describe 'welcome_watched!' do
    let(:subject) { user.welcome_watched! }

    it { subject }

    after { expect(Event.find_by(user: user, name: "onboarding.resource.welcome_watched").present?).to be(true) }
  end

  {
    welcome_watched_skipped!: 'onboarding.resource.welcome_watched_skipped',
    webinar_or_first_steps_joined_skipped!: 'onboarding.outing.webinar_or_first_steps_skipped',
    papotages_joined_skipped!: 'onboarding.outing.papotages_skipped',
    neighborhood_national_joined_skipped!: 'onboarding.neighborhood.national_skipped'
  }.each do |method, event_name|
    describe method.to_s do
      let(:subject) { user.public_send(method) }

      it { expect { subject }.to change { Event.where(user: user, name: event_name).count }.by(1) }
    end
  end

  describe 'onboarding_step_skipped!' do
    let(:subject) { user.onboarding_step_skipped!(step) }

    context 'valid step' do
      let(:step) { 'papotages' }

      it { expect(subject).to be(true) }
      it { expect { subject }.to change { Event.where(user: user, name: 'onboarding.outing.papotages_skipped').count }.by(1) }
    end

    context 'unknown step' do
      let(:step) { 'foo' }

      it { expect(subject).to be(false) }
      it { expect { subject }.not_to change { Event.count } }
    end

    context 'step is a method name' do
      let(:step) { 'papotages_joined_skipped!' }

      it { expect(subject).to be(false) }
    end

    context 'nil step' do
      let(:step) { nil }

      it { expect(subject).to be(false) }
    end
  end
end
