require 'rails_helper'
include CommunityHelper

RSpec.describe Solicitation, type: :model do
  let(:user) { create(:public_user) }

  describe 'create' do
    let(:solicitation) { create(:solicitation, postal_code: '44000', country: 'FR', recipient_consent_obtained: true) }
    let!(:moderation_area) { create(:moderation_area, departement: 44) }

    describe 'set moderation' do
      it { expect { solicitation }.to change { Entourage.count }.by 1 }
      it { expect { solicitation }.to change { EntourageModeration.count }.by 1 }
      it { expect(solicitation.reload.moderation).not_to be_nil }
      it { expect(solicitation.reload.moderation.moderator_id).to eq(moderation_area.animator_id) }
      it { expect(solicitation.reload.moderation.action_recipient_consent_obtained).to eq('Oui') }
    end
  end
end
