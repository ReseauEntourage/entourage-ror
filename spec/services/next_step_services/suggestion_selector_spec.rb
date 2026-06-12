require 'rails_helper'

describe NextStepServices::SuggestionSelector do
  let(:user) { FactoryBot.create(:public_user) }

  subject { described_class.new(user: user).call }

  before do
    user.update_column(:last_sign_in_at, 1.day.ago)
    NextStepSuggestion.delete_all
  end

  describe 'returns existing active non-expired step' do
    let!(:suggestion) { FactoryBot.create(:next_step_suggestion) }
    let!(:existing_step) { FactoryBot.create(:user_next_step, user: user, next_step_suggestion: suggestion, status: 'active', expires_at: 2.days.from_now) }

    it 'returns the existing active step without creating a new one' do
      expect(subject).to eq(existing_step)
      expect(UserNextStep.where(user: user).count).to eq(1)
    end
  end

  describe 'creates a new step when no active step exists' do
    let!(:suggestion) { FactoryBot.create(:next_step_suggestion, target_profile: 'all', min_engagement_level: 0, max_engagement_level: 4) }

    it 'creates and returns a new UserNextStep' do
      result = subject
      expect(result).to be_a(UserNextStep)
      expect(result).to be_persisted
      expect(result.status).to eq('active')
      expect(result.next_step_suggestion).to eq(suggestion)
    end
  end

  describe 'expired active step' do
    let!(:suggestion) { FactoryBot.create(:next_step_suggestion, target_profile: 'all', min_engagement_level: 0, max_engagement_level: 4, priority: 50) }
    let!(:expired_step) { FactoryBot.create(:user_next_step, user: user, next_step_suggestion: suggestion, status: 'active', expires_at: 1.day.ago) }

    it 'creates a new step when existing is expired' do
      result = subject
      expect(result).not_to eq(expired_step)
      expect(result).to be_a(UserNextStep)
      expect(result).to be_persisted
    end
  end

  describe 'respects target_profile filter' do
    let!(:offer_help_suggestion) do
      FactoryBot.create(:next_step_suggestion, target_profile: 'offer_help', min_engagement_level: 0, max_engagement_level: 4, priority: 90)
    end
    let!(:ask_for_help_suggestion) do
      FactoryBot.create(:next_step_suggestion, target_profile: 'ask_for_help', min_engagement_level: 0, max_engagement_level: 4, priority: 80)
    end

    it 'selects suggestion matching the user goal' do
      user.update_column(:goal, 'offer_help')
      result = subject
      expect(result.next_step_suggestion).to eq(offer_help_suggestion)
    end

    it 'selects suggestion matching ask_for_help goal' do
      user.update_column(:goal, 'ask_for_help')
      result = subject
      expect(result.next_step_suggestion).to eq(ask_for_help_suggestion)
    end
  end

  describe 'respects engagement level filter' do
    let!(:level_2_3_suggestion) do
      FactoryBot.create(:next_step_suggestion, suggestion_type: 'group', target_profile: 'all',
        min_engagement_level: 2, max_engagement_level: 3, priority: 60)
    end
    let!(:level_0_1_suggestion) do
      FactoryBot.create(:next_step_suggestion, suggestion_type: 'first_step', target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 1, priority: 100)
    end

    it 'selects level-appropriate suggestion for level 0 user' do
      result = subject
      expect(result.next_step_suggestion).to eq(level_0_1_suggestion)
    end
  end

  describe 'ignores recently dismissed types' do
    let!(:main_suggestion) do
      FactoryBot.create(:next_step_suggestion, suggestion_type: 'first_step', target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 4, priority: 100)
    end
    let!(:fallback_suggestion) do
      FactoryBot.create(:next_step_suggestion, :fallback, target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 4, priority: 1)
    end

    before do
      dismissed_step = FactoryBot.create(:user_next_step, user: user, next_step_suggestion: main_suggestion,
        status: 'dismissed', dismissed_at: 5.days.ago)
    end

    it 'skips recently dismissed suggestion types and uses fallback' do
      result = subject
      expect(result.next_step_suggestion).to eq(fallback_suggestion)
    end
  end

  describe 'dormant user' do
    let!(:reengagement_suggestion) do
      FactoryBot.create(:next_step_suggestion, :reengagement, target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 3, priority: 50)
    end
    let!(:fallback_suggestion) do
      FactoryBot.create(:next_step_suggestion, :fallback, target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 3, priority: 1)
    end

    before { user.update_column(:last_sign_in_at, 45.days.ago) }

    it 'selects reengagement suggestion for dormant user' do
      result = subject
      expect(result.next_step_suggestion).to eq(reengagement_suggestion)
    end
  end

  describe 'fallback when nothing matches' do
    let!(:fallback_suggestion) do
      FactoryBot.create(:next_step_suggestion, :fallback, target_profile: 'all',
        min_engagement_level: 0, max_engagement_level: 3, priority: 1)
    end
    let!(:high_level_suggestion) do
      FactoryBot.create(:next_step_suggestion, suggestion_type: 'group', target_profile: 'all',
        min_engagement_level: 3, max_engagement_level: 3, priority: 80)
    end

    it 'returns fallback suggestion when no level-appropriate match' do
      # user is at level 0, only level 3 suggestion exists (non-fallback)
      result = subject
      expect(result.next_step_suggestion).to eq(fallback_suggestion)
    end
  end
end
