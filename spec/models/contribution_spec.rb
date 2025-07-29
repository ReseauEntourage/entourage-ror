require 'rails_helper'
include CommunityHelper

RSpec.describe Contribution, type: :model do
  let(:user) { create(:public_user) }

  describe 'create' do
    let(:contribution) { create(:contribution, postal_code: '44000', country: 'FR') }
    let!(:moderation_area) { create(:moderation_area, departement: 44) }

    describe 'set moderation' do
      it { expect { contribution }.to change { Entourage.count }.by 1 }
      it { expect { contribution }.to change { EntourageModeration.count }.by 1 }
      it { expect(contribution.reload.moderation).not_to be_nil }
      it { expect(contribution.reload.moderation.moderator_id).to eq(moderation_area.animator_id) }
    end
  end
end
