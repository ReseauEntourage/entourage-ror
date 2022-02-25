require 'rails_helper'

describe UserService do
  describe '.firebase_properties' do
    let(:user) { double }

    def props *addresses
      addresses = addresses.map { |country, postal_code| Address.new(country: country, postal_code: postal_code) }
      allow(user).to receive(:addresses).and_return(addresses)
      allow(user).to receive(:goal).and_return(:ask_for_help)
      allow(user).to receive(:interest_list).and_return([:rencontrer_sdf, :event_sdf])
      UserService.firebase_properties(user)
    end

    it { expect(props()).to eq(
      ActionZoneDep: 'not_set',
      ActionZoneCP:  'not_set',
      Goal: 'ask_for_help',
      Interests: 'event_sdf,rencontrer_sdf'
    )}

    it { expect(props(['FR', nil])).to include(
      ActionZoneDep: 'not_set',
      ActionZoneCP:  'not_set'
    )}

    it { expect(props(['DE', '12345'])).to include(
      ActionZoneDep: 'not_FR',
      ActionZoneCP:  'not_FR'
    )}

    it { expect(props(['FR', '85XXX'])).to include(
      ActionZoneDep: '85',
      ActionZoneCP:  'not_set'
    )}

    it { expect(props(['FR', '75008'])).to include(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['FR', '92001'], ['FR', '75008'])).to include(
      ActionZoneDep: '75,92',
      ActionZoneCP:  '75008,92001'
    )}

    it { expect(props(['FR', '92XXX'], ['FR', '75008'])).to include(
      ActionZoneDep: '75,92',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['DE', '12345'], ['FR', '75008'])).to include(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}

    it { expect(props(['FR', nil], ['FR', '75008'])).to include(
      ActionZoneDep: '75',
      ActionZoneCP:  '75008'
    )}


    it { expect(props(['FR', nil], ['DE', '12345'])).to include(
      ActionZoneDep: 'not_FR',
      ActionZoneCP:  'not_FR'
    )}
  end
end
