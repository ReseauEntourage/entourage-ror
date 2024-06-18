require 'rails_helper'

describe OutingsServices::Finder do
  let(:user) { create(:public_user, address: address, travel_distance: 200) }
  let!(:outing_0) { create(:outing, :outing_class, latitude: 0, longitude: 0, title: "Foot", interest_list: ["sport"]) }
  let!(:outing_1) { create(:outing, :outing_class, latitude: 1, longitude: 1, title: "Ball", interest_list: ["jeux"]) }

  let(:address) { create(:address, place_name: 'address', latitude: latitude, longitude: longitude, postal_code: "75020") }
  let(:interests) { [] }
  let(:interests_1) { [] }
  let(:interests_2) { [] }

  let(:response) { OutingsServices::Finder.new(user, { interests: interests }).find_all.map(&:title) }

  describe "find_all" do
    let(:zone_0) { nil }
    let(:zone_1) { nil }

    describe "close to user" do
      let(:latitude) { 0.5 }
      let(:longitude) { 0.5 }

      it { expect(response).to eq(["Foot", "Ball"]) }
    end

    describe "far from user" do
      let(:latitude) { 10 }
      let(:longitude) { 10 }

      it { expect(response).to eq([]) }
    end

    describe "with interests" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "no interests filter" do
        let(:interests) { [] }
        it { expect(response).to eq(["Foot", "Ball"]) }
      end

      describe "interests matching" do
        let(:interests) { ["sport"] }
        it { expect(response).to eq(["Foot"]) }
      end

      describe "interests not matching" do
        let(:interests) { ["cuisine"] }
        it { expect(response).to eq([]) }
      end
    end
  end
end
