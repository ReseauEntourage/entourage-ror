require 'rails_helper'

describe EntourageServices::Pins do
  let(:user) { FactoryBot.create(:pro_user_paris) }
  let!(:pin) { FactoryBot.create(:entourage, pin: true, pins: ['75']) }
  let!(:outing) { FactoryBot.create(:outing, status: :open, online: true) }

  describe 'pinned_for' do
    it 'should find a pin' do
      expect(EntourageServices::Pins.pinned_for user).to eq(pin.id)
    end

    it 'should not find a pin with wrong address' do
      allow(user.address).to receive(:postal_code) { '13000' }

      expect(EntourageServices::Pins.pinned_for user).to be_nil
    end

    it 'should not find a pin if entourage is not a pin' do
      pin.update_attribute(:pin, false)

      expect(EntourageServices::Pins.pinned_for user).to be_nil
    end
  end

  describe 'pinned_for with joined action' do
    let!(:join_request) { FactoryBot.create(:join_request, joinable: pin, user: user, status: "accepted") }

    it 'should find a pin even after join_request' do
      expect(EntourageServices::Pins.pinned_for user).to eq(pin.id)
    end
  end

  describe 'outing_pinned' do
    it 'should find outing' do
      expect(EntourageServices::Pins.outing_pinned user).to eq(outing.id)
    end

    it 'should not find outing if closed' do
      outing.update_attribute(:status, :closed)
      expect(EntourageServices::Pins.outing_pinned user).to be_nil
    end
  end

  describe 'outing_pinned with joined outing' do
    let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: "accepted") }

    it 'should find outing even after join_request' do
      expect(EntourageServices::Pins.outing_pinned user).to eq(outing.id)
    end
  end

  describe 'find' do
    it 'should find pins' do
      expect(EntourageServices::Pins.find user, nil).to eq([pin.id, outing.id])
    end

    it 'should find action pins for ask_for_helps' do
      expect(EntourageServices::Pins.find user, ['contribution_social']).to eq([])
      expect(EntourageServices::Pins.find user, ['ask_for_help_social']).to eq([pin.id])
    end

    it 'should find action pins for contributions' do
      pin.update_attribute(:entourage_type, 'contribution')

      expect(EntourageServices::Pins.find user, ['contribution_social']).to eq([pin.id])
      expect(EntourageServices::Pins.find user, ['ask_for_help_social']).to eq([])
    end

    it 'should find outing pin' do
      expect(EntourageServices::Pins.find user, ['outing']).to eq([outing.id])
    end
  end
end
