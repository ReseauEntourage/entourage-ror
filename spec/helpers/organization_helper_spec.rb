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
    it { expect(meters_to_printable_km(0)).to eq "0.0" }
    it { expect(meters_to_printable_km(1000)).to eq "1.0" }
    it { expect(meters_to_printable_km(1500)).to eq "1.5" }
    it { expect(meters_to_printable_km(1999)).to eq "2.0" }
  end
  
  describe 'marker_index' do
    it { expect(marker_index 0 ).to eq "1" }
    it { expect(marker_index 1 ).to eq "2" }
    it { expect(marker_index 7 ).to eq "8" }
    it { expect(marker_index 8 ).to eq "9" }
    it { expect(marker_index 9 ).to eq "A" }
    it { expect(marker_index 10).to eq "B" }
    it { expect(marker_index 33).to eq "Y" }
    it { expect(marker_index 34).to eq "Z" }
    it { expect(marker_index 35).to eq "?" }
    it { expect(marker_index 36).to eq "?" }
  end
end
