require 'rails_helper'

describe PoiServices::Soliguide do
  describe 'apply?' do
    let!(:option_soliguide) { FactoryBot.create(:option_soliguide) }

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

    it 'should be valid far from Paris' do
      expect(PoiServices::Soliguide.new({
        latitude: 48.8586,
        longitude: 2.50
      }).apply?).to eq(true)
    end

    # Lyon
    it 'should be valid for Lyon' do
      expect(PoiServices::Soliguide.new({
        latitude: 45.75,
        longitude: 4.85
      }).apply?).to eq(true)
    end
  end

  describe 'query_params' do
    subject { PoiServices::Soliguide.new(params).query_params }

    context 'minimal search' do
      let(:params) { {
        latitude: 47.3,
        longitude: -1.55,
      } }

      it {
        expect(subject).to eq({
          location: {
            areas: {
              country: :fr
            },
            distance: PoiServices::Soliguide::DISTANCE_MIN,
            coordinates: [-1.55, 47.3],
            geoType: "position"
          },
          options: {},
        })
      }
    end

    context 'search in Paris' do
      let(:params) { {
        latitude: 48.86,
        longitude: 2.34,
      } }

      it {
        expect(subject).to eq({
          location: {
            areas: {
              country: :fr
            },
            distance: PoiServices::Soliguide::DISTANCE_MIN,
            coordinates: [2.34, 48.86],
            geoType: "position"
          },
          options: {},
        })
      }
    end

    context 'with query and multiple categories' do
      let(:params) { {
        distance: 5.0,
        latitude: 47.3,
        longitude: -1.55,
        category_ids: "1,2",
        query: 'myquery'
      } }

      it {
        expect(subject).to eq({
          location: {
            areas: {
              country: :fr
            },
            distance: 5.0,
            coordinates: [-1.55, 47.3],
            geoType: "position"
          },
          options: {},
          word: 'myquery',
        })
      }
    end

    context 'without query and single category' do
      let(:params) { {
        distance: 5.0,
        latitude: 47.3,
        longitude: -1.55,
        category_ids: "1"
      } }

      it {
        expect(subject).to eq({
          location: {
            areas: {
              country: :fr
            },
            distance: 5.0,
            coordinates: [-1.55, 47.3],
            geoType: "position"
          },
          options: {},
          categories: ["food"],
        })
      }
    end
  end
end
