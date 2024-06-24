require 'rails_helper'

describe NeighborhoodServices::Finder do
  let(:user) { create(:public_user, address: address, travel_distance: 200) }
  let!(:neighborhood_0) { create(:neighborhood, latitude: 0, longitude: 0, name: "foot", description: "volley", zone: zone_0, postal_code: "75000", interest_list: ["sport"]) }
  let!(:neighborhood_1) { create(:neighborhood, latitude: 1, longitude: 1, name: "ball", description: "barre", zone: zone_1, postal_code: "75001", interest_list: ["jeux"]) }

  let(:address) { create(:address, place_name: 'address', latitude: latitude, longitude: longitude, postal_code: "75020") }
  let(:interests) { [] }
  let(:interests_1) { [] }
  let(:interests_2) { [] }

  let(:response) { NeighborhoodServices::Finder.search(user: user, params: { q: q, interests: interests }).map(&:name) }

  describe "search" do
    let(:zone_0) { nil }
    let(:zone_1) { nil }

    describe "close to one" do
      let(:q) { nil }
      let(:latitude) { 0.1 }
      let(:longitude) { 0.1 }

      it { expect(response).to eq(["foot", "ball"]) }
    end

    describe "close to the other" do
      let(:q) { nil }
      let(:latitude) { 1.1 }
      let(:longitude) { 1.1 }

      it { expect(response).to eq(["ball", "foot"]) }
    end

    describe "far from user" do
      let(:q) { nil }
      let(:latitude) { 10 }
      let(:longitude) { 10 }

      it { expect(response).to eq([]) }
    end

    describe "far from user but with same departement" do
      let(:q) { nil }
      let(:latitude) { 10 }
      let(:longitude) { 10 }
      let(:zone_0) { :departement }

      it { expect(response).to eq(["foot"]) }
    end

    describe "ordered by no zone" do
      let(:q) { nil }
      let(:latitude) { 0.1 }
      let(:longitude) { 0.1 }

      context "one has a zone" do
        let(:zone_0) { :ville }
        let(:zone_1) { nil }

        it { expect(response).to eq(["ball", "foot"]) }
      end

      context "the other has a zone" do
        let(:zone_0) { nil }
        let(:zone_1) { :ville }

        it { expect(response).to eq(["foot", "ball"]) }
      end
    end

    describe "with q" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "with q on one" do
        let(:q) { "foo" }
        it { expect(response).to eq(["foot"]) }
      end

      describe "with q on the other" do
        let(:q) { "bal" }
        it { expect(response).to eq(["ball"]) }
      end

      describe "does not find for description" do
        let(:q) { "bar" }
        it { expect(response).to eq([]) }
      end
    end

    describe "with interests" do
      let(:q) { nil }
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "no interests filter" do
        let(:interests) { [] }
        it { expect(response).to eq(["foot", "ball"]) }
      end

      describe "interests matching" do
        let(:interests) { ["sport"] }
        it { expect(response).to eq(["foot"]) }
      end

      describe "interests not matching" do
        let(:interests) { ["cuisine"] }
        it { expect(response).to eq([]) }
      end
    end
  end
end
