require 'rails_helper'

describe EntourageServices::EntourageLocationRandomizer do

  before { Rails.env.stub(:test?) { false } }

  let(:entourage) { FactoryGirl.create(:entourage) }
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