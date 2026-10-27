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

  describe 'first_event_joined!' do
    context 'physical event' do
      let(:subject) { user.first_event_joined!('physique') }

      it { expect { subject }.to change { Event.where(user: user, name: 'onboarding.outing.first_event').count }.by(1) }
      it { expect { subject }.not_to change { Event.where(user: user, name: 'onboarding.outing.papotages').count } }

      it 'tracks the outing type' do
        subject

        expect(Event.find_by(user: user, name: 'onboarding.outing.first_event').properties).to eq('outing_type' => 'physique')
      end
    end

    context 'papotage' do
      let(:subject) { user.first_event_joined!('papotage') }

      it { expect { subject }.to change { Event.where(user: user, name: 'onboarding.outing.first_event').count }.by(1) }

      it 'still tracks the legacy event read by the installed apps' do
        expect { subject }.to change { Event.where(user: user, name: 'onboarding.outing.papotages').count }.by(1)
      end
    end
  end

  describe '.first_event_type' do
    let(:online) { true }
    let(:title) { 'Atelier cuisine' }
    let(:sf_category) { :convivialite }
    let(:outing) { create(:outing, :outing_class, online: online, title: title, sf_category: sf_category) }

    subject { described_class.first_event_type(outing) }

    it { is_expected.to eq('visio') }

    context 'physical' do
      let(:online) { false }

      it { is_expected.to eq('physique') }
    end

    context 'papotage' do
      let(:title) { 'Papotage du jeudi' }

      it { is_expected.to eq('papotage') }
    end

    context 'first steps webinar' do
      let(:sf_category) { :welcome_entourage_local }

      it { is_expected.to be_nil }
    end

    context 'webinar' do
      let(:sf_category) { :atelier_mdlr }

      it { is_expected.to be_nil }
    end
  end

  describe 'welcome journey removal' do
    def removed_events
      Event.where(user: user, name: 'onboarding.parcours.removed')
    end

    context 'when the last step is crossed' do
      before do
        user.welcome_watched!
        user.neighborhood_national_joined_skipped!
        user.webinar_or_first_steps_joined!
      end

      it 'removes the journey with the reason completed' do
        expect { user.first_event_joined!('visio') }.to change { removed_events.count }.by(1)

        expect(removed_events.first.properties).to eq('reason' => 'completed')
      end

      it 'removes the journey when the last step is skipped' do
        expect { user.papotages_joined_skipped! }.to change { removed_events.count }.by(1)

        expect(removed_events.first.properties).to eq('reason' => 'completed')
      end

      it 'tracks the removal once' do
        user.papotages_joined_skipped!

        expect { user.first_event_joined!('visio') }.not_to change { removed_events.count }
      end
    end

    context 'when a step is crossed before the last one' do
      it { expect { user.welcome_watched! }.not_to change { removed_events.count } }
    end

    context 'when the inactivity delay is over' do
      before { user.update_columns(created_at: 20.days.ago, first_sign_in_at: 20.days.ago) }

      it 'persists the removal before the step, which does not bring the journey back' do
        user.welcome_watched!

        expect(removed_events.count).to eq(1)
        expect(removed_events.first.properties).to eq('reason' => 'inactivity')
        expect(removed_events.first.created_at).to be < 5.days.ago
        expect(Event.where(user: user, name: 'onboarding.resource.welcome_watched').count).to eq(1)
        expect(Onboarding::Journey.new(user).removed?).to be(true)
      end
    end

    context 'when the journey is hidden' do
      it 'still tracks the steps' do
        user.hide_onboarding_journey!

        expect { user.webinar_or_first_steps_joined! }.to change { Event.where(user: user, name: 'onboarding.outing.webinar_or_first_steps').count }.by(1)
        expect(removed_events.first.properties).to eq('reason' => 'hidden')
      end
    end

    describe 'hide_onboarding_journey!' do
      it { expect { user.hide_onboarding_journey! }.to change { removed_events.count }.by(1) }
      it { expect { 2.times { user.hide_onboarding_journey! } }.to change { removed_events.count }.by(1) }
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
