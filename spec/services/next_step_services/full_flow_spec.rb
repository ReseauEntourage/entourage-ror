require 'rails_helper'

# Integration spec for the full suggestion lifecycle:
# EngagementLevel + SuggestionSelector working together.
describe 'NextStep full suggestion lifecycle' do
  let(:user) { FactoryBot.create(:public_user) }

  before do
    user.update_column(:last_sign_in_at, 1.day.ago)
    NextStepSuggestion.delete_all
    UserNextStep.where(user: user).delete_all
  end

  let(:selector) { NextStepServices::SuggestionSelector.new(user: user) }

  # ---------------------------------------------------------------------------
  # Level 0 → level 1 changes the suggestion type
  # ---------------------------------------------------------------------------
  describe 'level 0 → level 1 changes the suggestion type' do
    let!(:level_0_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 0,
        priority: 80
      )
    end

    let!(:level_1_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'event',
        target_profile: 'all',
        min_engagement_level: 1,
        max_engagement_level: 2,
        priority: 80
      )
    end

    it 'selects the level-0 suggestion for a user with no join requests' do
      result = NextStepServices::SuggestionSelector.new(user: user).call
      expect(result.next_step_suggestion).to eq(level_0_suggestion)
    end

    it 'selects the level-1 suggestion after a user gains an accepted join request' do
      # Simulate an action: create an accepted join request
      FactoryBot.create(:join_request, user: user, status: 'accepted')

      # EngagementLevel should now return 1
      level = NextStepServices::EngagementLevel.new(user: user).call
      expect(level).to eq(1)

      # SuggestionSelector should pick the level-1 suggestion (no existing active step)
      result = NextStepServices::SuggestionSelector.new(user: user).call
      expect(result.next_step_suggestion).to eq(level_1_suggestion)
    end
  end

  # ---------------------------------------------------------------------------
  # Dismissing all types falls back to fallback suggestion
  # ---------------------------------------------------------------------------
  describe 'dismissing all types falls back to fallback suggestion' do
    let!(:first_step_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 100
      )
    end

    let!(:event_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'event',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 80
      )
    end

    let!(:connection_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'connection',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 70
      )
    end

    let!(:fallback_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'fallback',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 1
      )
    end

    before do
      # Dismiss all non-fallback suggestion types within the last 30 days
      [first_step_suggestion, event_suggestion, connection_suggestion].each do |s|
        FactoryBot.create(:user_next_step,
          user: user,
          next_step_suggestion: s,
          status: 'dismissed',
          dismissed_at: 5.days.ago
        )
      end
    end

    it 'returns the fallback suggestion when all other types are recently dismissed' do
      result = NextStepServices::SuggestionSelector.new(user: user).call
      expect(result).not_to be_nil
      expect(result.next_step_suggestion).to eq(fallback_suggestion)
    end

    it 'does not create a duplicate step if fallback is already active' do
      # First call: creates fallback step
      first = NextStepServices::SuggestionSelector.new(user: user).call
      expect(first.next_step_suggestion).to eq(fallback_suggestion)

      # Second call: returns the same step
      second = NextStepServices::SuggestionSelector.new(user: user).call
      expect(second.id).to eq(first.id)
      expect(UserNextStep.where(user: user, status: 'active').count).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # New suggestion immediately after completion
  # ---------------------------------------------------------------------------
  describe 'new suggestion available immediately after completion' do
    let!(:suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 50
      )
    end

    it 'creates a new suggestion even when the last completion was recent' do
      FactoryBot.create(:user_next_step,
        user: user,
        next_step_suggestion: suggestion,
        status: 'completed',
        acted_at: 5.minutes.ago
      )

      result = NextStepServices::SuggestionSelector.new(user: user).call
      expect(result).not_to be_nil
      expect(result.next_step_suggestion).to eq(suggestion)
    end
  end

  # ---------------------------------------------------------------------------
  # Dormant user always gets reengagement before fallback
  # ---------------------------------------------------------------------------
  describe 'dormant user always gets reengagement before fallback' do
    let(:dormant_user) { FactoryBot.create(:public_user, last_sign_in_at: 35.days.ago) }

    let!(:reengagement_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'reengagement',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 50
      )
    end

    let!(:fallback_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'fallback',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 1
      )
    end

    it 'EngagementLevel returns :dormant for user who has not signed in for 35 days' do
      level = NextStepServices::EngagementLevel.new(user: dormant_user).call
      expect(level).to eq(:dormant)
    end

    it 'SuggestionSelector returns reengagement for dormant user (not fallback)' do
      result = NextStepServices::SuggestionSelector.new(user: dormant_user).call
      expect(result).not_to be_nil
      expect(result.next_step_suggestion).to eq(reengagement_suggestion)
      expect(result.next_step_suggestion.suggestion_type).to eq('reengagement')
    end

    it 'falls back to fallback suggestion when reengagement type is dismissed' do
      FactoryBot.create(:user_next_step,
        user: dormant_user,
        next_step_suggestion: reengagement_suggestion,
        status: 'dismissed',
        dismissed_at: 5.days.ago
      )

      result = NextStepServices::SuggestionSelector.new(user: dormant_user).call
      expect(result).not_to be_nil
      expect(result.next_step_suggestion).to eq(fallback_suggestion)
    end
  end
end
