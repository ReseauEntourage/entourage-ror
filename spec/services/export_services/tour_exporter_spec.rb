require 'rails_helper'

describe ExportServices::TourExporter do

  before { Timecop.freeze(Time.local(2015)) }
  after { Timecop.return }

  let!(:tour) { FactoryGirl.create(:tour) }


  describe 'export_tour_points' do
    let!(:tour_points) { FactoryGirl.create_list(:tour_point, 3, tour: tour) }
    let(:exporter) { ExportServices::TourExporter.new(tour: tour) }

    it 'generates a csv with tour points' do
      csv = exporter.export_tour_points
      expect(CSV.read(csv)).to eq([["latitude;Longitude;Date"], ["1.5;1.5;2015-07-07 12:31:43 +0200"], ["1.5;1.5;2015-07-07 12:31:43 +0200"], ["1.5;1.5;2015-07-07 12:31:43 +0200"]])
    end
  end

  describe 'export_encounters' do
    let!(:tour_points) { FactoryGirl.create_list(:encounter, 3, tour: tour) }
    let(:exporter) { ExportServices::TourExporter.new(tour: tour) }

    it 'generates a csv with tour points' do
      csv = exporter.export_encounters
      expect(CSV.read(csv)).to eq([["Nom;latitude;Longitude;Date"], ["Toto;48.870424;2.30681949999996;2015-01-01 00:00:00 +0100"], ["Toto;48.870424;2.30681949999996;2015-01-01 00:00:00 +0100"], ["Toto;48.870424;2.30681949999996;2015-01-01 00:00:00 +0100"]])
    end
  end
end