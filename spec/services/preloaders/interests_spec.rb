require 'rails_helper'

describe Preloaders::Interests do
  describe '.preload' do
    let(:neighborhood_1) { create(:neighborhood, interests: [:sport, :culture]) }
    let(:neighborhood_2) { create(:neighborhood, interests: []) }

    it 'preloads interest_names for each record without an extra query per record' do
      Preloaders::Interests.preload([neighborhood_1, neighborhood_2])

      expect(neighborhood_1.interest_names).to match_array(%w[sport culture])
      expect(neighborhood_2.interest_names).to eq([])
    end

    it 'reads interest_names from the preloaded value instead of querying interests' do
      Preloaders::Interests.preload([neighborhood_1])

      expect(neighborhood_1).not_to receive(:interests)
      expect(neighborhood_1.interest_names).to match_array(%w[sport culture])
    end

    it 'does nothing when given an empty array' do
      expect { Preloaders::Interests.preload([]) }.not_to raise_error
    end
  end
end
