require 'rails_helper'

describe Preloaders::Neighborhood do
  describe '.preload_future_outings_count' do
    let(:neighborhood) { create(:neighborhood) }

    it 'sets preloaded_future_outings_count to the number of active future outings' do
      create(:outing, :with_neighborhood, user: neighborhood.user, neighborhoods: [neighborhood])
      create(:outing, :with_neighborhood, user: neighborhood.user, neighborhoods: [neighborhood])

      Preloaders::Neighborhood.preload_future_outings_count([neighborhood])

      expect(neighborhood.future_outings_count).to eq(2)
    end

    it 'does not count past outings' do
      outing = create(:outing, :with_neighborhood, user: neighborhood.user, neighborhoods: [neighborhood])
      outing.update_column(:metadata, outing.metadata.merge(
        starts_at: 2.days.ago, ends_at: 1.day.ago
      ))

      Preloaders::Neighborhood.preload_future_outings_count([neighborhood])

      expect(neighborhood.future_outings_count).to eq(0)
    end

    it 'does not count cancelled outings' do
      create(:outing, :with_neighborhood, user: neighborhood.user, neighborhoods: [neighborhood], status: :cancelled)

      Preloaders::Neighborhood.preload_future_outings_count([neighborhood])

      expect(neighborhood.future_outings_count).to eq(0)
    end

    it 'sets the count to 0 when the neighborhood has no future outing' do
      Preloaders::Neighborhood.preload_future_outings_count([neighborhood])

      expect(neighborhood.future_outings_count).to eq(0)
    end

    it 'does nothing when given an empty array' do
      expect { Preloaders::Neighborhood.preload_future_outings_count([]) }.not_to raise_error
    end
  end
end
