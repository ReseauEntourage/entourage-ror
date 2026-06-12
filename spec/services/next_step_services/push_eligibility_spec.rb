require 'rails_helper'

describe NextStepServices::PushEligibility do
  let(:user) { FactoryBot.create(:pro_user) }

  subject { described_class.new(user: user).eligible? }

  before do
    user.update_columns(
      last_sign_in_at: 2.hours.ago,
      goal: 'offer_help',
      options: {}
    )
  end

  def create_device_token(u = user)
    FactoryBot.create(:user_application,
      user: u,
      push_token: "token_#{SecureRandom.hex(4)}",
      device_family: UserApplication::ANDROID
    )
  end

  context 'with all conditions met' do
    before { create_device_token }

    it { is_expected.to eq(true) }
  end

  context 'rule 1: no device token' do
    it 'returns false when no user_applications registered' do
      expect(subject).to eq(false)
    end
  end

  context 'rule 2: outside allowed hours' do
    let(:eligibility) { described_class.new(user: user) }

    before { create_device_token }

    it 'returns false at hour 7 (before 8h)' do
      allow(eligibility).to receive(:within_allowed_hours?).and_return(false)
      expect(eligibility.eligible?).to eq(false)
    end

    it 'returns false at hour 22 (at 22h)' do
      allow(eligibility).to receive(:within_allowed_hours?).and_return(false)
      expect(eligibility.eligible?).to eq(false)
    end

    it 'returns true at hour 8' do
      allow(eligibility).to receive(:within_allowed_hours?).and_return(true)
      expect(eligibility.eligible?).to eq(true)
    end

    it 'returns true at hour 21' do
      allow(eligibility).to receive(:within_allowed_hours?).and_return(true)
      expect(eligibility.eligible?).to eq(true)
    end

    it 'within_allowed_hours? returns false for hour 7' do
      allow(Time.zone).to receive(:now).and_return(Time.zone.now.change(hour: 7))
      expect(eligibility.send(:within_allowed_hours?)).to eq(false)
    end

    it 'within_allowed_hours? returns false for hour 22' do
      allow(Time.zone).to receive(:now).and_return(Time.zone.now.change(hour: 22))
      expect(eligibility.send(:within_allowed_hours?)).to eq(false)
    end

    it 'within_allowed_hours? returns true for hour 8' do
      allow(Time.zone).to receive(:now).and_return(Time.zone.now.change(hour: 8))
      expect(eligibility.send(:within_allowed_hours?)).to eq(true)
    end

    it 'within_allowed_hours? returns true for hour 21' do
      allow(Time.zone).to receive(:now).and_return(Time.zone.now.change(hour: 21))
      expect(eligibility.send(:within_allowed_hours?)).to eq(true)
    end
  end

  context 'rule 3: recently signed in (< 30 min ago)' do
    before do
      create_device_token
      user.update_columns(last_sign_in_at: 10.minutes.ago)
    end

    it { is_expected.to eq(false) }
  end

  context 'rule 4: push sent less than 24h ago' do
    before do
      create_device_token
      user.update_columns(options: { 'last_push_at' => 1.hour.ago.iso8601 })
    end

    it { is_expected.to eq(false) }

    context 'push sent more than 24h ago' do
      before { user.update_columns(options: { 'last_push_at' => 25.hours.ago.iso8601 }) }

      it { is_expected.to eq(true) }
    end
  end

  context 'rule 5: push paused' do
    before do
      create_device_token
      user.update_columns(options: { 'push_paused_until' => 10.days.from_now.iso8601 })
    end

    it { is_expected.to eq(false) }

    context 'pause expired in the past' do
      before { user.update_columns(options: { 'push_paused_until' => 1.day.ago.iso8601 }) }

      it { is_expected.to eq(true) }
    end
  end

  context 'rule 6: isolated person (ask_for_help) without explicit opt-in' do
    before do
      create_device_token
      user.update_columns(goal: 'ask_for_help', options: {})
    end

    it { is_expected.to eq(false) }

    context 'with explicit push_enabled = true' do
      before { user.update_columns(options: { 'push_enabled' => true }) }

      it { is_expected.to eq(true) }
    end
  end

  context 'rule 7: neighbor (offer_help) with explicit opt-out' do
    before do
      create_device_token
      user.update_columns(goal: 'offer_help', options: { 'push_enabled' => false })
    end

    it { is_expected.to eq(false) }

    context 'neighbor without opt-out (push_enabled not set)' do
      before { user.update_columns(options: {}) }

      it { is_expected.to eq(true) }
    end
  end
end
