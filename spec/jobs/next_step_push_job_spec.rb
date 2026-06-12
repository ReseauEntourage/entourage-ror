require 'rails_helper'

describe NextStepPushJob do
  let(:user) { FactoryBot.create(:pro_user) }
  let!(:suggestion) do
    FactoryBot.create(:next_step_suggestion,
      suggestion_type: 'first_step',
      target_profile: 'all',
      min_engagement_level: 0,
      max_engagement_level: 4,
      title_template: 'Un événement a lieu près de chez vous',
      cta_action: 'entourage://outings',
      priority: 50
    )
  end

  before do
    user.update_columns(
      last_sign_in_at: 2.hours.ago,
      goal: 'offer_help',
      options: {}
    )
    NextStepSuggestion.where.not(id: suggestion.id).delete_all
    allow(NotificationJob).to receive(:perform_later)
  end

  def create_device_token(u = user)
    FactoryBot.create(:user_application,
      user: u,
      push_token: "token_#{SecureRandom.hex(4)}",
      device_family: UserApplication::ANDROID
    )
  end

  describe 'no device token' do
    it 'does nothing when no device token registered' do
      described_class.new.perform(user.id)
      expect(NotificationJob).not_to have_received(:perform_later)
    end
  end

  describe 'recently signed in' do
    before do
      create_device_token
      user.update_columns(last_sign_in_at: 5.minutes.ago)
    end

    it 'does nothing when user signed in less than 30 min ago' do
      described_class.new.perform(user.id)
      expect(NotificationJob).not_to have_received(:perform_later)
    end
  end

  describe 'already pushed recently' do
    before do
      create_device_token
      user.update_columns(options: { 'last_push_at' => 1.hour.ago.iso8601 })
    end

    it 'does nothing when push sent less than 24h ago' do
      described_class.new.perform(user.id)
      expect(NotificationJob).not_to have_received(:perform_later)
    end
  end

  describe 'isolated person without opt-in' do
    before do
      create_device_token
      user.update_columns(goal: 'ask_for_help', options: {})
    end

    it 'does nothing for PI without explicit push_enabled' do
      described_class.new.perform(user.id)
      expect(NotificationJob).not_to have_received(:perform_later)
    end
  end

  describe 'eligible user' do
    let!(:token) { create_device_token }

    it 'calls NotificationJob with correct arguments' do
      described_class.new.perform(user.id)
      expect(NotificationJob).to have_received(:perform_later).once.with(
        0,
        'Entourage',
        'Un événement a lieu près de chez vous',
        token.push_token,
        user.community.slug,
        { type: 'next_step', deep_link: 'entourage://outings' },
        nil
      )
    end

    it 'updates last_push_at in user options' do
      described_class.new.perform(user.id)
      user.reload
      expect(user.options['last_push_at']).to be_present
    end

    it 'increments push_count_without_tap' do
      described_class.new.perform(user.id)
      user.reload
      expect(user.options['push_count_without_tap']).to eq(1)
    end
  end

  describe 'silence after 4 pushes without tap' do
    let!(:token) { create_device_token }

    before do
      user.update_columns(options: { 'push_count_without_tap' => 3 })
    end

    it 'sets push_paused_until after 4th push without tap' do
      described_class.new.perform(user.id)
      user.reload
      expect(user.options['push_paused_until']).to be_present
      paused_until = Time.zone.parse(user.options['push_paused_until'])
      expect(paused_until).to be > 29.days.from_now
    end

    it 'resets push_count_without_tap to 0' do
      described_class.new.perform(user.id)
      user.reload
      expect(user.options['push_count_without_tap']).to eq(0)
    end
  end
end
