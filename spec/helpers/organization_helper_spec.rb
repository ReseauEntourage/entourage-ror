require 'rails_helper'

describe OrganizationHelper, :type => :helper do
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
