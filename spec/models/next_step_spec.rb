require 'rails_helper'

RSpec.describe NextStep, type: :model do
  let(:user) { create(:user) }

  it 'belongs to a user' do
    expect(create(:next_step, user: user).user).to eq(user)
  end

  describe 'a single active next step per user' do
    it 'refuses a second active next step for the same user, in the database' do
      create(:next_step, user: user)

      expect {
        build(:next_step, user: user).save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'accepts a new active next step once the previous one is no longer active' do
      create(:next_step, user: user).ignore!

      expect { create(:next_step, user: user) }.not_to raise_error
    end

    it 'accepts active next steps for different users' do
      create(:next_step, user: user)

      expect { create(:next_step, user: create(:user)) }.not_to raise_error
    end
  end

  describe '#target' do
    it 'loads the target from its type and id' do
      neighborhood = create(:neighborhood)
      next_step = create(:next_step, user: user, kind: 'neighborhood', target_type: 'Neighborhood', target_id: neighborhood.id)

      expect(next_step.target).to eq(neighborhood)
    end

    it 'is nil without a target' do
      expect(create(:next_step, user: user, kind: 'smalltalk').target).to be_nil
    end
  end

  describe 'status changes' do
    let(:next_step) { create(:next_step, user: user) }

    it 'records a realisation' do
      next_step.realise!

      expect(next_step.reload).to have_attributes(status: 'realised', realised_at: be_present)
    end

    it 'records an ignore' do
      next_step.ignore!

      expect(next_step.reload).to have_attributes(status: 'ignored', ignored_at: be_present)
    end

    it 'records an expiry' do
      next_step.expire!

      expect(next_step.reload).to have_attributes(status: 'expired', closed_at: be_present)
    end
  end

  it 'rejects an unknown kind' do
    expect(build(:next_step, user: user, kind: 'unknown')).not_to be_valid
  end
end

RSpec.describe NextStepInteraction, type: :model do
  it 'belongs to a user and to the hero it is about' do
    interaction = create(:next_step_interaction)

    expect(interaction.next_step.user).to eq(interaction.user)
  end

  it 'requires the hero for an interaction on the hero' do
    expect(build(:next_step_interaction, next_step: nil, placement: 'hero')).not_to be_valid
  end

  it 'requires the item kind for an interaction on the others' do
    expect(build(:next_step_interaction, next_step: nil, placement: 'others', item_kind: nil)).not_to be_valid
    expect(build(:next_step_interaction, next_step: nil, placement: 'others', item_kind: 'outing', target_type: 'Outing', target_id: 1)).to be_valid
  end
end
