require 'rails_helper'

describe UserService do
  describe '.firebase_properties' do
    let(:user) { double }

    def props *addresses
      addresses = addresses.map { |country, postal_code| Address.new(country: country, postal_code: postal_code) }
      allow(user).to receive(:addresses).and_return(addresses)
      UserService.firebase_properties(user)
    end

    it { expect(props()).to eq(
      ActionZoneDep: 'not_set',
      ActionZoneCP:  'not_set'
    )}

    it { expect(props(['FR', nil])).to eq(
      ActionZoneDep: 'not_set',
      ActionZoneCP:  'not_set'
    )}

    it { expect(props(['DE', '12345'])).to eq(
      ActionZoneDep: 'not_FR',
      ActionZoneCP:  'not_FR'
    )}

    it { expect(props(['FR', '85XXX'])).to eq(
      ActionZoneDep: '85',
      ActionZoneCP:  'not_set'
    )}

    it { expect(props(['FR', '75008'])).to eq(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['FR', '92001'], ['FR', '75008'])).to eq(
      ActionZoneDep: '75,92',
      ActionZoneCP:  '75008,92001'
    )}

    it { expect(props(['FR', '92XXX'], ['FR', '75008'])).to eq(
      ActionZoneDep: '75,92',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['DE', '12345'], ['FR', '75008'])).to eq(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['FR', nil], ['FR', '75008'])).to eq(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}


    it { expect(props(['FR', nil], ['DE', '12345'])).to eq(
      ActionZoneDep: 'not_FR',
      ActionZoneCP:  'not_FR'
    )}
  end
end
