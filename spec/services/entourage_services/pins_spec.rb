require 'rails_helper'

describe EntourageServices::Pins do
  let(:user) { FactoryGirl.create(:pro_user_paris) }
  let!(:pin) { FactoryGirl.create(:entourage, pin: true, pins: '75') }
  let!(:outing) { FactoryGirl.create(:outing, pin: true) }

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

  describe 'outing_pinned' do
    it 'should find a pin' do
      expect(EntourageServices::Pins.outing_pinned).to eq(outing.id)
    end

    it 'should find 121064 if no pinned outing is configured' do
      outing.update_attribute(:pin, false)
      expect(EntourageServices::Pins.outing_pinned).to eq(121064)
    end
  end

  describe 'find' do
    it 'should find pins' do
      expect(EntourageServices::Pins.find user, nil).to eq([pin.id, outing.id])
    end

    it 'should find action pins for contributions or ask_for_helps' do
      expect(EntourageServices::Pins.find user, ['contribution_']).to eq([pin.id])
      expect(EntourageServices::Pins.find user, ['ask_for_help_']).to eq([pin.id])
    end

    it 'should find outing pin' do
      expect(EntourageServices::Pins.find user, ['outing']).to eq([outing.id])
    end
  end
end