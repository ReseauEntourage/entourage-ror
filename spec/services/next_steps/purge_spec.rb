require 'rails_helper'

RSpec.describe NextSteps::Purge do
  let(:user) { create(:public_user) }

  # not active: the unique index allows a single active next step per user
  def step_created_at time, user: self.user, **attributes
    create(:next_step, user: user, status: 'expired', created_at: time, first_displayed_at: time, expires_at: time + 3.days, **attributes)
  end

  def interaction_created_at time, next_step:, **attributes
    create(:next_step_interaction, user: next_step&.user || user, next_step: next_step, created_at: time, **attributes)
  end

  describe '.expired' do
    it 'deletes the next steps and the interactions older than 6 months, and keeps the recent ones' do
      old = step_created_at(7.months.ago)
      recent = step_created_at(5.months.ago)
      interaction_created_at(7.months.ago, next_step: old)
      recent_interaction = interaction_created_at(5.months.ago, next_step: recent)
      interaction_created_at(8.months.ago, next_step: nil, placement: 'others', item_kind: 'outing')

      result = described_class.expired

      expect(NextStep.all).to contain_exactly(recent)
      expect(NextStepInteraction.all).to contain_exactly(recent_interaction)
      expect(result).to eq(next_step_interactions: 2, next_steps: 1)
    end

    it 'deletes in several batches' do
      stub_const('NextSteps::Purge::BATCH_SIZE', 2)
      5.times { step_created_at(7.months.ago) }

      expect(described_class.expired).to eq(next_step_interactions: 0, next_steps: 5)
      expect(NextStep.count).to eq(0)
    end

    it 'keeps the exclusions of the last 30 days: a group ignored 10 days ago stays excluded' do
      step_created_at(7.months.ago)
      step_created_at(10.days.ago, kind: 'neighborhood', target_type: 'Neighborhood', target_id: 7, status: 'ignored', ignored_at: 10.days.ago)

      described_class.expired

      expect(NextSteps::Exclusions.new(user, placement: :hero).excluded_target_ids('neighborhood')).to eq([7])
    end

    it 'lets a gesture realised by a tap come back once the history is deleted' do
      step_created_at(7.months.ago, kind: 'become_ambassador', status: 'realised', realised_at: 7.months.ago)

      expect(NextSteps::Exclusions.new(user, placement: :hero).excluded_gesture?('become_ambassador')).to be(true)

      described_class.expired

      expect(NextSteps::Exclusions.new(user, placement: :hero).excluded_gesture?('become_ambassador')).to be(false)
    end

    it 'leaves the domain data alone' do
      create(:user_smalltalk, user: user, created_at: 10.days.ago)
      step_created_at(7.months.ago)

      described_class.expired

      expect(NextSteps::Exclusions.new(user, placement: :hero).smalltalk_recently_requested?).to be(true)
    end
  end

  describe '.for_user' do
    it 'deletes everything the engine kept about one user, and nothing about the others' do
      other = create(:public_user)
      mine = step_created_at(1.day.ago)
      theirs = step_created_at(1.day.ago, user: other)
      interaction_created_at(1.day.ago, next_step: mine)
      their_interaction = interaction_created_at(1.day.ago, next_step: theirs)

      result = described_class.for_user(user.id)

      expect(result).to eq(next_step_interactions: 1, next_steps: 1)
      expect(NextStep.all).to contain_exactly(theirs)
      expect(NextStepInteraction.all).to contain_exactly(their_interaction)
    end
  end
end
