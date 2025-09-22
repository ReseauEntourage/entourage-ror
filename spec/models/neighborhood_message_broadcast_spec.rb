require 'rails_helper'

RSpec.describe NeighborhoodMessageBroadcast, type: :model do
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:title) }

  let!(:neighborhood_75009) { create(:neighborhood, postal_code: "75009", zone: "ville") }
  let!(:neighborhood_75018) { create(:neighborhood, postal_code: "75018", zone: "departement") }
  let!(:neighborhood_44240) { create(:neighborhood, postal_code: "44240", zone: "departement") }
  let!(:neighborhood_29160) { create(:neighborhood, postal_code: "29160", zone: "no_zone") }

  describe "neighborhood_ids_in_departements_and_area_type" do
    let(:departements) { [] }
    let(:area_type) { "zone_all" }

    let(:subject) { NeighborhoodMessageBroadcast::neighborhood_ids_in_departements_and_area_type(departements, area_type) }

    context "finds no neighborhood when unexisting departement" do
      let(:departements) { ["35"] }

      it { expect(subject).to match_array([]) }
    end

    context "finds all departements of single departement" do
      let(:departements) { ["75"] }

      it { expect(subject).to match_array([neighborhood_75009.id, neighborhood_75018.id]) }
    end

    context "finds all departements of multiple departements" do
      let(:departements) { ["75", "44"] }

      it { expect(subject).to match_array([neighborhood_75009.id, neighborhood_75018.id, neighborhood_44240.id]) }
    end
  end
end
