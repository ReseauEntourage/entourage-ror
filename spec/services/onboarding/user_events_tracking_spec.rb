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
