require 'rails_helper'

describe NextStepPushSchedulerJob do
  before do
    allow(NextStepPushJob).to receive(:perform_async)
  end

  def create_validated_user(overrides = {})
    user = FactoryBot.create(:pro_user)
    attrs = {
      community: :entourage,
      deleted: false,
      validation_status: 'validated',
      first_sign_in_at: nil,
      last_sign_in_at: 10.days.ago  # default: recently active, not dormant
    }.merge(overrides)
    user.update_columns(attrs)
    user
  end

  describe 'batch 1: new inactive users' do
    let!(:new_inactive_user) do
      # Signed up 2-3 days ago, no join requests, last seen recently (not dormant)
      create_validated_user(
        first_sign_in_at: 2.days.ago - 6.hours,
        last_sign_in_at: 2.days.ago - 6.hours
      )
    end

    let!(:user_with_join_request) do
      u = create_validated_user(
        first_sign_in_at: 2.days.ago - 6.hours,
        last_sign_in_at: 2.days.ago - 6.hours
      )
      FactoryBot.create(:join_request, user: u)
      u
    end

    let!(:older_user) do
      create_validated_user(
        first_sign_in_at: 10.days.ago,
        last_sign_in_at: 10.days.ago
      )
    end

    it 'enqueues new users with no join requests' do
      described_class.new.perform
      expect(NextStepPushJob).to have_received(:perform_async).with(new_inactive_user.id)
    end

    it 'does not enqueue users with join requests' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(user_with_join_request.id)
    end

    it 'does not enqueue users who signed up more than 3 days ago' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(older_user.id)
    end
  end

  describe 'batch 2: users with recently expired suggestions' do
    let!(:suggestion) { FactoryBot.create(:next_step_suggestion) }

    let!(:user_with_expired_step) do
      # Use first_sign_in_at outside batch 1 window, last_sign_in_at outside dormant window
      create_validated_user(
        first_sign_in_at: 20.days.ago,
        last_sign_in_at: 10.days.ago
      )
    end
    let!(:expired_step) do
      FactoryBot.create(:user_next_step,
        user: user_with_expired_step,
        next_step_suggestion: suggestion,
        status: 'active',
        expires_at: 5.hours.ago
      )
    end

    let!(:user_with_fresh_step) do
      create_validated_user(
        first_sign_in_at: 20.days.ago,
        last_sign_in_at: 10.days.ago
      )
    end
    let!(:fresh_step) do
      FactoryBot.create(:user_next_step,
        user: user_with_fresh_step,
        next_step_suggestion: suggestion,
        status: 'active',
        expires_at: 30.minutes.ago
      )
    end

    let!(:user_with_old_step) do
      create_validated_user(
        first_sign_in_at: 20.days.ago,
        last_sign_in_at: 10.days.ago
      )
    end
    let!(:old_step) do
      FactoryBot.create(:user_next_step,
        user: user_with_old_step,
        next_step_suggestion: suggestion,
        status: 'active',
        expires_at: 30.hours.ago
      )
    end

    it 'enqueues users with suggestion expired between 1h and 25h ago' do
      described_class.new.perform
      expect(NextStepPushJob).to have_received(:perform_async).with(user_with_expired_step.id)
    end

    it 'does not enqueue users with suggestion expired less than 1h ago' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(user_with_fresh_step.id)
    end

    it 'does not enqueue users with suggestion expired more than 25h ago' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(user_with_old_step.id)
    end
  end

  describe 'batch 3: dormant users' do
    let!(:dormant_user) do
      create_validated_user(last_sign_in_at: 35.days.ago)
    end

    let!(:active_user) do
      create_validated_user(last_sign_in_at: 5.days.ago)
    end

    let!(:very_dormant_user) do
      create_validated_user(last_sign_in_at: 50.days.ago)
    end

    it 'enqueues dormant users (30-45 days since last sign in)' do
      described_class.new.perform
      expect(NextStepPushJob).to have_received(:perform_async).with(dormant_user.id)
    end

    it 'does not enqueue recently active users' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(active_user.id)
    end

    it 'does not enqueue users inactive for more than 45 days' do
      described_class.new.perform
      expect(NextStepPushJob).not_to have_received(:perform_async).with(very_dormant_user.id)
    end
  end
end
