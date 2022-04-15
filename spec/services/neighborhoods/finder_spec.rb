require 'rails_helper'

describe Neighborhoods::Finder do
  let(:user) { FactoryBot.create(:public_user, address: address) }
  let!(:neighborhood_0) { FactoryBot.create(:neighborhood, latitude: 0, longitude: 0, name: "foot", description: "volley") }
  let!(:neighborhood_1) { FactoryBot.create(:neighborhood, latitude: 1, longitude: 1, name: "ball", description: "barre") }

  let(:address) { FactoryBot.create(:address, place_name: 'address', latitude: latitude, longitude: longitude) }

  let(:response) { Neighborhoods::Finder.search(user, q).map(&:name) }


  describe "search" do
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

    describe "with q" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "with q on one" do
        let(:q) { "foo" }
        it { expect(response).to eq(["foot"]) }
      end

      describe "with q on the other" do
        let(:q) { "bar" }
        it { expect(response).to eq(["ball"]) }
      end
    end
  end
end
