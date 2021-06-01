require 'rails_helper'

describe PoiServices::Soliguide do
  let!(:tour) { FactoryBot.create(:tour) }

  describe 'apply?' do
    # Paris
    it 'should be valid for Paris' do
      expect(PoiServices::Soliguide.new({
        latitude: 48.8586,
        longitude: 2.3411
      }).apply?).to eq(true)
    end

    it 'should be valid close to Paris' do
      expect(PoiServices::Soliguide.new({
        latitude: 48.88,
        longitude: 2.36
      }).apply?).to eq(true)
    end

    it 'should not be valid far from Paris' do
      expect(PoiServices::Soliguide.new({
        latitude: 48.8586,
        longitude: 2.50
      }).apply?).to eq(false)
    end

    # Lyon
    it 'should be valid for Lyon' do
      expect(PoiServices::Soliguide.new({
        latitude: 45.75,
        longitude: 4.85
      }).apply?).to eq(true)
    end

    it 'should be valid close to Lyon' do
      expect(PoiServices::Soliguide.new({
        latitude: 45.77,
        longitude: 4.87
      }).apply?).to eq(true)
    end

    it 'should not be valid far from Lyon' do
      expect(PoiServices::Soliguide.new({
        latitude: 45.90,
        longitude: 4.60
      }).apply?).to eq(false)
    end
  end

  describe 'get_redirection' do
    it {
      expect(PoiServices::Soliguide.new({
        latitude: 47.3,
        longitude: -1.55,
        distance: 5.0,
        category_ids: "1,2",
        query: 'myquery'
      }).get_redirection).to eq "#{PoiServices::Soliguide::API_HOST}?distance=5.0&latitude=47.3&longitude=-1.55&query=myquery"
    }

    it {
      expect(PoiServices::Soliguide.new({
        latitude: 47.3,
        longitude: -1.55,
        distance: 5.0,
        category_ids: "1"
      }).get_redirection).to eq "#{PoiServices::Soliguide::API_HOST}?categories=1&distance=5.0&latitude=47.3&longitude=-1.55"
    }
  end
end
