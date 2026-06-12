require 'rails_helper'
include CommunityHelper

describe Api::V1::NextStepController do
  let(:user) { FactoryBot.create(:public_user) }
  let!(:suggestion) do
    FactoryBot.create(:next_step_suggestion,
      suggestion_type: 'first_step',
      target_profile: 'all',
      min_engagement_level: 0,
      max_engagement_level: 4,
      title_template: 'Un événement a lieu près de chez vous',
      reason_template: 'Parce que vous êtes dans votre quartier',
      cta_label: 'Voir les détails',
      cta_action: 'entourage://outings',
      priority: 50
    )
  end

  before do
    user.update_column(:last_sign_in_at, 1.day.ago)
    NextStepSuggestion.where.not(id: suggestion.id).delete_all
  end

  describe 'GET show' do
    context 'not signed in' do
      before { get :show }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { get :show, params: { token: user.token } }

      subject { JSON.parse(response.body) }

      it { expect(response.status).to eq(200) }

      it 'returns a next_step' do
        expect(subject).to have_key('next_step')
        expect(subject['next_step']).not_to be_nil
      end

      it 'returns expected fields' do
        ns = subject['next_step']
        expect(ns).to have_key('id')
        expect(ns).to have_key('suggestion_type')
        expect(ns).to have_key('title')
        expect(ns).to have_key('reason')
        expect(ns).to have_key('cta_label')
        expect(ns).to have_key('cta_action')
        expect(ns).to have_key('expires_at')
      end

      it 'returns correct suggestion data' do
        ns = subject['next_step']
        expect(ns['suggestion_type']).to eq('first_step')
        expect(ns['cta_label']).to eq('Voir les détails')
        expect(ns['cta_action']).to eq('entourage://outings')
      end
    end

    context 'signed in with no matching suggestion' do
      before do
        NextStepSuggestion.delete_all
        get :show, params: { token: user.token }
      end

      subject { JSON.parse(response.body) }

      it { expect(response.status).to eq(200) }

      it 'returns nil next_step' do
        expect(subject['next_step']).to be_nil
      end
    end
  end

  describe 'PATCH complete' do
    let!(:user_next_step) do
      FactoryBot.create(:user_next_step, user: user, next_step_suggestion: suggestion,
        status: 'active', expires_at: 2.days.from_now)
    end

    context 'not signed in' do
      before { patch :complete, params: { id: user_next_step.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { patch :complete, params: { id: user_next_step.id, token: user.token } }

      it { expect(response.status).to eq(200) }

      it 'marks the step as completed' do
        expect(user_next_step.reload.status).to eq('completed')
        expect(user_next_step.acted_at).to be_present
      end
    end

    context 'with another user token' do
      let(:other_user) { FactoryBot.create(:public_user) }

      before { patch :complete, params: { id: user_next_step.id, token: other_user.token } }

      it { expect(response.status).to eq(404) }
    end
  end

  describe 'PATCH dismiss' do
    let!(:user_next_step) do
      FactoryBot.create(:user_next_step, user: user, next_step_suggestion: suggestion,
        status: 'active', expires_at: 2.days.from_now)
    end

    context 'not signed in' do
      before { patch :dismiss, params: { id: user_next_step.id } }
      it { expect(response.status).to eq(401) }
    end

    context 'signed in' do
      before { patch :dismiss, params: { id: user_next_step.id, token: user.token } }

      it { expect(response.status).to eq(200) }

      it 'marks the step as dismissed' do
        expect(user_next_step.reload.status).to eq('dismissed')
        expect(user_next_step.dismissed_at).to be_present
      end
    end

    context 'with another user token' do
      let(:other_user) { FactoryBot.create(:public_user) }

      before { patch :dismiss, params: { id: user_next_step.id, token: other_user.token } }

      it { expect(response.status).to eq(404) }
    end
  end
end
