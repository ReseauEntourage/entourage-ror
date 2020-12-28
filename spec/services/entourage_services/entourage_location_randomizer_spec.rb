require 'rails_helper'

describe EntourageServices::EntourageLocationRandomizer do

  before do
    Rails.env.stub(:test?) { false }
    EntourageServices::GeocodingService.stub(:enable_callback) { false }
  end

  let(:entourage) { FactoryBot.create(:entourage) }
  let(:randomizer) { EntourageServices::EntourageLocationRandomizer.new(entourage: entourage) }

  #sin and cos max value is 1
  let(:max_deviation) { 250.0/111300 * Math.sqrt(1) * 1 }

  describe 'random_longitude' do
    it { expect(randomizer.random_longitude).to be_within(max_deviation).of(entourage.longitude) }
  end

  describe 'random_latitude' do
    it { expect(randomizer.random_latitude).to be_within(max_deviation).of(entourage.latitude) }
  end
end
