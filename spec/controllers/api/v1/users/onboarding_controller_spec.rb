require 'rails_helper'
include CommunityHelper

RSpec.describe Api::V1::UsersController, type: :controller do
  let(:user) { FactoryBot.create(:pro_user) }

  before { user.update_column(:last_sign_in_at, 1.day.ago) }

  describe 'GET #onboarding_questions' do
    context 'not authenticated' do
      before { get :onboarding_questions }

      it { expect(response.status).to eq(401) }
    end

    context 'authenticated' do
      before { get :onboarding_questions, params: { token: user.token } }

      subject { JSON.parse(response.body) }

      it { expect(response.status).to eq(200) }

      it 'returns a questions array with 3 elements' do
        expect(subject['questions']).to be_an(Array)
        expect(subject['questions'].length).to eq(3)
      end

      it 'each question has the expected keys' do
        subject['questions'].each do |question|
          expect(question).to have_key('key')
          expect(question).to have_key('title')
          expect(question).to have_key('type')
          expect(question).to have_key('options')
          expect(question).to have_key('current_value')
        end
      end

      it 'returns questions with the correct keys' do
        keys = subject['questions'].map { |q| q['key'] }
        expect(keys).to contain_exactly('goal', 'preferred_format', 'availability')
      end

      it 'returns goal question with cards type' do
        goal_question = subject['questions'].find { |q| q['key'] == 'goal' }
        expect(goal_question['type']).to eq('cards')
      end

      it 'returns availability question with chips type' do
        availability_question = subject['questions'].find { |q| q['key'] == 'availability' }
        expect(availability_question['type']).to eq('chips')
      end

      context 'when user has no goal set' do
        before do
          user.update_column(:goal, nil)
          get :onboarding_questions, params: { token: user.token }
        end

        it 'reflects nil as current_value for goal' do
          goal_question = subject['questions'].find { |q| q['key'] == 'goal' }
          expect(goal_question['current_value']).to be_nil
        end
      end

      context 'when user already has a goal set' do
        before do
          user.update_column(:goal, 'offer_help')
          get :onboarding_questions, params: { token: user.token }
        end

        it 'reflects the existing goal as current_value' do
          goal_question = subject['questions'].find { |q| q['key'] == 'goal' }
          expect(goal_question['current_value']).to eq('offer_help')
        end
      end

      context 'when user has preferred_format set in options' do
        before do
          user.update_column(:options, { 'preferred_format' => 'group' })
          get :onboarding_questions, params: { token: user.token }
        end

        it 'reflects the existing preferred_format as current_value' do
          pf_question = subject['questions'].find { |q| q['key'] == 'preferred_format' }
          expect(pf_question['current_value']).to eq('group')
        end
      end
    end
  end

  describe 'PATCH #onboarding_preferences' do
    context 'not authenticated' do
      before { patch :onboarding_preferences }

      it { expect(response.status).to eq(401) }
    end

    context 'updating goal' do
      before do
        patch :onboarding_preferences, params: { token: user.token, goal: 'offer_help' }
      end

      it { expect(response.status).to eq(200) }

      it 'saves the goal on the user' do
        expect(user.reload.goal).to eq('offer_help')
      end
    end

    context 'updating preferred_format' do
      before do
        patch :onboarding_preferences, params: { token: user.token, preferred_format: 'individual' }
      end

      it { expect(response.status).to eq(200) }

      it "saves preferred_format in user.options['preferred_format']" do
        expect(user.reload.options['preferred_format']).to eq('individual')
      end

      it 'does not clobber other existing options keys' do
        user.update_column(:options, { 'existing_key' => 'existing_value' })
        patch :onboarding_preferences, params: { token: user.token, preferred_format: 'group' }
        expect(user.reload.options['existing_key']).to eq('existing_value')
        expect(user.reload.options['preferred_format']).to eq('group')
      end
    end

    context 'updating availability' do
      # The User model requires numeric day keys (1-7) and time-slot arrays.
      # Day 1 = Monday, Day 7 = Sunday.
      let(:valid_availability) { { '6' => ['10:00-12:00'], '7' => ['14:00-16:00'] } }

      before do
        patch :onboarding_preferences, params: {
          token: user.token,
          availability: valid_availability
        }
      end

      it { expect(response.status).to eq(200) }

      it 'saves availability on the user' do
        availability = user.reload.availability
        expect(availability['6']).to eq(['10:00-12:00'])
      end
    end

    context 'updating multiple params in one request' do
      let(:valid_availability) { { '6' => ['10:00-12:00'] } }

      before do
        patch :onboarding_preferences, params: {
          token: user.token,
          goal: 'ask_for_help',
          preferred_format: 'both',
          availability: valid_availability
        }
      end

      it { expect(response.status).to eq(200) }

      it 'saves all params in a single transaction' do
        user.reload
        expect(user.goal).to eq('ask_for_help')
        expect(user.options['preferred_format']).to eq('both')
        expect(user.availability['6']).to eq(['10:00-12:00'])
      end
    end
  end
end
