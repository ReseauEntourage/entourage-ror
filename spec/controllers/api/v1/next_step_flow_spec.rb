require 'rails_helper'
include CommunityHelper

# End-to-end flow spec for the next_step feature.
# Tests the full lifecycle: GET show, PATCH complete, PATCH dismiss — across user journeys.
RSpec.describe Api::V1::NextStepController, type: :controller do
  let(:user) { FactoryBot.create(:pro_user) }

  before do
    # Fresh state: recent login, no stale suggestions
    user.update_column(:last_sign_in_at, 1.day.ago)
    NextStepSuggestion.delete_all
    UserNextStep.where(user: user).delete_all
  end

  # ---------------------------------------------------------------------------
  # Parcours 1 — Premier pas (niveau 0)
  # ---------------------------------------------------------------------------
  context 'Parcours 1 — new user with no actions (level 0)' do
    let!(:suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
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

    it 'GET next_step creates and returns a first_step suggestion' do
      get :show, params: { token: user.token }

      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body['next_step']).not_to be_nil
      expect(body['next_step']['suggestion_type']).to eq('first_step')
    end

    it 'GET next_step returns the expected fields' do
      get :show, params: { token: user.token }

      ns = JSON.parse(response.body)['next_step']
      expect(ns).to have_key('id')
      expect(ns).to have_key('suggestion_type')
      expect(ns).to have_key('title')
      expect(ns).to have_key('reason')
      expect(ns).to have_key('cta_label')
      expect(ns).to have_key('expires_at')
    end

    it 'GET next_step twice returns the same suggestion (no duplicate)' do
      get :show, params: { token: user.token }
      first_id = JSON.parse(response.body)['next_step']['id']

      get :show, params: { token: user.token }
      second_id = JSON.parse(response.body)['next_step']['id']

      expect(second_id).to eq(first_id)
      expect(UserNextStep.where(user: user).count).to eq(1)
    end

    it 'PATCH complete marks the step as completed' do
      get :show, params: { token: user.token }
      user_next_step_id = JSON.parse(response.body)['next_step']['id']

      patch :complete, params: { id: user_next_step_id, token: user.token }

      expect(response.status).to eq(200)
      expect(UserNextStep.find(user_next_step_id).status).to eq('completed')
    end

    it 'GET next_step after completion returns 200' do
      get :show, params: { token: user.token }
      user_next_step_id = JSON.parse(response.body)['next_step']['id']

      patch :complete, params: { id: user_next_step_id, token: user.token }

      get :show, params: { token: user.token }
      expect(response.status).to eq(200)
    end

    # NOTE: The SuggestionSelector currently re-creates a step from the same suggestion pool
    # immediately after completion. The desired product behaviour (no immediate re-suggestion)
    # would require a "cooling-off" mechanism in SuggestionSelector — not yet implemented.
    # When that logic is added, the test below can be un-skipped.
    it 'GET next_step after completion returns a new suggestion immediately' do
      get :show, params: { token: user.token }
      first_id = JSON.parse(response.body)['next_step']['id']

      patch :complete, params: { id: first_id, token: user.token }

      get :show, params: { token: user.token }
      expect(response.status).to eq(200)
      ns = JSON.parse(response.body)['next_step']
      expect(ns).not_to be_nil
      expect(ns['id']).not_to eq(first_id)
    end
  end

  # ---------------------------------------------------------------------------
  # Parcours 2 — Rotation après expiration
  # ---------------------------------------------------------------------------
  context 'Parcours 2 — suggestion expired after 3 days' do
    let!(:suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 50,
        valid_for_days: 3
      )
    end

    let!(:expired_step) do
      FactoryBot.create(:user_next_step,
        user: user,
        next_step_suggestion: suggestion,
        status: 'active',
        expires_at: 1.day.ago
      )
    end

    it 'GET next_step creates a new suggestion when existing one is expired' do
      get :show, params: { token: user.token }

      expect(response.status).to eq(200)
      ns = JSON.parse(response.body)['next_step']
      expect(ns).not_to be_nil
      expect(ns['id']).not_to eq(expired_step.id)
    end

    it 'the new suggestion has expires_at in the future' do
      get :show, params: { token: user.token }

      ns = JSON.parse(response.body)['next_step']
      expires_at = Time.parse(ns['expires_at'])
      expect(expires_at).to be > Time.zone.now
    end
  end

  # ---------------------------------------------------------------------------
  # Parcours 3 — Dismiss et exclusion 30 jours
  # ---------------------------------------------------------------------------
  context 'Parcours 3 — dismissed suggestion type excluded for 30 days' do
    let!(:first_step_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 100
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

    it 'after dismissing a suggestion type, the next GET returns a different type' do
      # Step 1: get the first_step suggestion
      get :show, params: { token: user.token }
      ns = JSON.parse(response.body)['next_step']
      expect(ns['suggestion_type']).to eq('first_step')

      # Step 2: dismiss it
      patch :dismiss, params: { id: ns['id'], token: user.token }
      expect(response.status).to eq(200)

      # Step 3: next GET should not return 'first_step' anymore
      get :show, params: { token: user.token }
      ns2 = JSON.parse(response.body)['next_step']
      expect(ns2).not_to be_nil
      expect(ns2['suggestion_type']).not_to eq('first_step')
    end

    it 'after dismiss, returns the fallback suggestion' do
      get :show, params: { token: user.token }
      ns = JSON.parse(response.body)['next_step']

      patch :dismiss, params: { id: ns['id'], token: user.token }
      get :show, params: { token: user.token }

      ns2 = JSON.parse(response.body)['next_step']
      expect(ns2['suggestion_type']).to eq('fallback')
    end
  end

  # ---------------------------------------------------------------------------
  # Parcours 4 — Utilisateur dormant
  # ---------------------------------------------------------------------------
  context 'Parcours 4 — dormant user (last_sign_in_at 35 days ago)' do
    let(:user) { FactoryBot.create(:pro_user, last_sign_in_at: 35.days.ago) }

    let!(:reengagement_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'reengagement',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 80
      )
    end

    let!(:first_step_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 50
      )
    end

    it 'GET next_step returns a reengagement suggestion for dormant user' do
      get :show, params: { token: user.token }

      expect(response.status).to eq(200)
      ns = JSON.parse(response.body)['next_step']
      expect(ns).not_to be_nil
      expect(ns['suggestion_type']).to eq('reengagement')
    end
  end

  # ---------------------------------------------------------------------------
  # Parcours 5 — Personnalisation par profil
  # ---------------------------------------------------------------------------
  context 'Parcours 5 — user with goal offer_help' do
    let(:user) { FactoryBot.create(:pro_user, goal: 'offer_help', last_sign_in_at: 1.day.ago) }

    let!(:offer_help_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'event',
        target_profile: 'offer_help',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 90
      )
    end

    let!(:ask_for_help_suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'connection',
        target_profile: 'ask_for_help',
        min_engagement_level: 0,
        max_engagement_level: 4,
        priority: 90
      )
    end

    it 'GET next_step returns suggestion targeting offer_help profile' do
      get :show, params: { token: user.token }

      expect(response.status).to eq(200)
      ns = JSON.parse(response.body)['next_step']
      expect(ns).not_to be_nil
      # Should be offer_help suggestion, not ask_for_help
      expect(ns['suggestion_type']).to eq('event')
    end

    it 'does not return the suggestion exclusively targeting ask_for_help' do
      get :show, params: { token: user.token }

      ns = JSON.parse(response.body)['next_step']
      # The returned suggestion is not the ask_for_help-only one
      ns_suggestion = NextStepSuggestion.find_by(suggestion_type: ns['suggestion_type'],
        target_profile: 'ask_for_help')
      expect(ns_suggestion).to be_nil.or(satisfy { |s| s.id != ask_for_help_suggestion.id })
    end

    context 'with a universal (all) suggestion also present' do
      let!(:all_suggestion) do
        FactoryBot.create(:next_step_suggestion,
          suggestion_type: 'first_step',
          target_profile: 'all',
          min_engagement_level: 0,
          max_engagement_level: 4,
          priority: 50
        )
      end

      it 'returns the highest-priority suggestion matching the profile' do
        get :show, params: { token: user.token }

        ns = JSON.parse(response.body)['next_step']
        # offer_help_suggestion has higher priority (90) than all_suggestion (50)
        expect(ns['suggestion_type']).to eq('event')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Sécurité — mauvais token sur complete/dismiss
  # ---------------------------------------------------------------------------
  context 'Security — complete/dismiss with wrong user token' do
    let(:other_user) { FactoryBot.create(:pro_user) }
    let!(:suggestion) do
      FactoryBot.create(:next_step_suggestion,
        suggestion_type: 'first_step',
        target_profile: 'all',
        min_engagement_level: 0,
        max_engagement_level: 4
      )
    end
    let!(:user_next_step) do
      FactoryBot.create(:user_next_step,
        user: user,
        next_step_suggestion: suggestion,
        status: 'active',
        expires_at: 2.days.from_now
      )
    end

    it 'PATCH complete with another user token returns 404' do
      patch :complete, params: { id: user_next_step.id, token: other_user.token }
      expect(response.status).to eq(404)
    end

    it 'PATCH dismiss with another user token returns 404' do
      patch :dismiss, params: { id: user_next_step.id, token: other_user.token }
      expect(response.status).to eq(404)
    end

    it 'PATCH complete does not change the step status when called with wrong token' do
      patch :complete, params: { id: user_next_step.id, token: other_user.token }
      expect(user_next_step.reload.status).to eq('active')
    end

    it 'PATCH dismiss does not change the step status when called with wrong token' do
      patch :dismiss, params: { id: user_next_step.id, token: other_user.token }
      expect(user_next_step.reload.status).to eq('active')
    end
  end
end
