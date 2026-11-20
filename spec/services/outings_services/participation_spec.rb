require 'rails_helper'

describe OutingsServices::Participation do
  let(:organizer) { create(:public_user) }
  let(:outing) { create(:outing, user: organizer) }
  let(:user) { create(:public_user) }
  let(:service) { described_class.new(outing: outing, user: user) }

  before { create(:join_request, user: organizer, joinable: outing, status: :accepted, role: :organizer) }

  describe '#join' do
    it 'registers the user as an accepted participant' do
      membership = service.join(distance: 12.5)

      expect(membership.errors).to be_empty
      expect(membership).to be_persisted
      expect(membership).to have_attributes(status: 'accepted', role: 'participant', distance: 12.5)
      expect(outing.reload.member_ids).to match_array([organizer.id, user.id])
    end

    it 'registers an ambassador as organizer only when asked' do
      ambassador = create(:public_user, targeting_profile: :ambassador)

      expect(described_class.new(outing: outing, user: ambassador).join(role: 'organizer').role).to eq('organizer')
      expect(described_class.new(outing: outing, user: ambassador).join.role).to eq('participant')
    end

    it 'never makes a regular user an organizer' do
      expect(service.join(role: 'organizer').role).to eq('participant')
    end

    it 'accepts again a user who cancelled' do
      service.join
      service.leave

      expect(service.join.status).to eq('accepted')
      expect(JoinRequest.where(joinable: outing, user: user).count).to eq(1)
    end

    it 'does nothing more when the user already joined' do
      service.join

      expect(GroupMailer).not_to receive(:event_joined_confirmation)
      expect { service.join }.not_to change { JoinRequest.count }
    end
  end

  describe '#leave' do
    it 'cancels the participation' do
      service.join

      membership = service.leave

      expect(membership.errors).to be_empty
      expect(membership.reload.status).to eq('cancelled')
    end

    it 'returns nil when the user never joined' do
      expect(service.leave).to be_nil
    end

    it 'refuses to remove the creator' do
      membership = described_class.new(outing: outing, user: organizer).leave

      expect(membership.errors).not_to be_empty
      expect(membership.reload.status).to eq('accepted')
    end
  end
end
