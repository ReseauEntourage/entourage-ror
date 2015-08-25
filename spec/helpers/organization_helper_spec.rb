require 'rails_helper'

describe OrganizationHelper, :type => :helper do

  describe 'duration' do
    it { expect(duration(spy('tour', duration: 1))).to eq '1 seconde' }
    it { expect(duration(spy('tour', duration: 30))).to eq '30 secondes' }
    it { expect(duration(spy('tour', duration: 60))).to eq '1 minute' }
    it { expect(duration(spy('tour', duration: 90))).to eq '1 minute' }
    it { expect(duration(spy('tour', duration: 3 * 60))).to eq '3 minutes' }
    it { expect(duration(spy('tour', duration: 60 * 60))).to eq '1 heure' }
    it { expect(duration(spy('tour', duration: 63 * 60))).to eq '1 heure 3 minutes' }
    it { expect(duration(spy('tour', duration: 123 * 60))).to eq '2 heures 3 minutes' }
    it { expect(duration(spy('tour', duration: 123 * 60 + 0.0000123))).to eq '2 heures 3 minutes' }
  end

  describe 'meters_to_printable_km' do
    it { expect(meters_to_printable_km(0)).to eq "0" }
    it { expect(meters_to_printable_km(1000)).to eq "1" }
    it { expect(meters_to_printable_km(1500)).to eq "1.5" }
    it { expect(meters_to_printable_km(1999)).to eq "2" }
  end
end
