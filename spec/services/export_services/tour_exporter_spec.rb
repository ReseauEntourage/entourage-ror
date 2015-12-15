require 'rails_helper'

describe ExportServices::TourExporter do
  let!(:tour) { FactoryGirl.create(:tour) }

  describe 'export_tour_points' do
    let!(:tour_points) { FactoryGirl.create_list(:tour_point, 3, tour: tour) }
    let(:exporter) { ExportServices::TourExporter.new(tour: tour) }

    it 'generates a csv with tour points' do
      csv = exporter.export_tour_points
      rows = CSV.read(csv)
      expect(rows.count).to eq(4)
      expect(rows[0]).to eq(["latitude;Longitude;Date"])
      columns = rows[1].first.split(";")
      expect(columns[0]).to eq("1.5")
      expect(columns[1]).to eq("1.5")
    end
  end

  describe 'export_encounters' do
    let!(:tour_points) { FactoryGirl.create_list(:encounter, 3, tour: tour) }
    let(:exporter) { ExportServices::TourExporter.new(tour: tour) }

    it 'generates a csv with tour points' do
      csv = exporter.export_encounters
      rows = CSV.read(csv)
      expect(rows.count).to eq(4)
      expect(rows[0]).to eq(["Nom;latitude;Longitude;Date"])
      columns = rows[1].first.split(";")
      expect(columns[0]).to eq("Toto")
      expect(columns[1]).to eq("48.870424")
      expect(columns[2]).to eq("2.30681949999996")
    end
  end
end