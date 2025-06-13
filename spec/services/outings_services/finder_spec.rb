require 'rails_helper'

describe OutingsServices::Finder do
  let(:user) { create(:public_user, address: address, travel_distance: 200) }
  let!(:outing_foot) { create(:outing, :outing_class, latitude: 0, longitude: 0, title: "Foot", interest_list: ["sport"], exclusive_to: foot_exclusivity) }
  let!(:outing_ball) { create(:outing, :outing_class, latitude: 1, longitude: 1, title: "Ball", interest_list: ["jeux"], exclusive_to: ball_exclusivity) }
  let(:foot_exclusivity) { nil }
  let(:ball_exclusivity) { nil }

  let(:address) { create(:address, place_name: 'address', latitude: latitude, longitude: longitude, postal_code: "75020") }
  let(:interests) { [] }
  let(:interest_list) { nil }
  let(:q) { nil }

  let(:response) { OutingsServices::Finder.new(user, { q: q, interests: interests, interest_list: interest_list }).find_all.map(&:title) }

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

    describe "not active" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      before { outing_foot.update_attribute(:status, :closed) }

      it { expect(response).to eq(["Ball"]) }
    end

    describe "with q" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "with q on one" do
        let(:q) { "foo" }
        it { expect(response).to eq(["Foot"]) }
      end

      describe "with q on the other" do
        let(:q) { "bal" }
        it { expect(response).to eq(["Ball"]) }
      end

      describe "with q on the other" do
        let(:q) { "bar" }
        it { expect(response).to eq([]) }
      end
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

    describe "with interest_list" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }

      describe "no interest_list filter" do
        let(:interest_list) { "" }
        it { expect(response).to eq(["Foot", "Ball"]) }
      end

      describe "interest_list matching" do
        let(:interest_list) { "sport" }
        it { expect(response).to eq(["Foot"]) }
      end

      describe "interest_list matching one of each" do
        let(:interest_list) { "sport,jeux" }
        it { expect(response).to match_array(["Foot", "Ball"]) }
      end

      describe "interest_list not matching" do
        let(:interest_list) { "cuisine" }
        it { expect(response).to eq([]) }
      end
    end

    describe "for_user scope" do
      let(:latitude) { 0 }
      let(:longitude) { 0 }
      let!(:foot_exclusivity) { 'ask_for_help' }
      let!(:ball_exclusivity) { 'offer_help' }
      let!(:outing_public) { create(:outing, :outing_class, latitude: 0, longitude: 0, title: "Public", interest_list: ["cuisine"], exclusive_to: nil) }

      describe "with ask_for_help user" do
        let(:user) { create(:ask_for_help_user, address: address, travel_distance: 200) }

        it "returns outings with exclusive_to nil or ask_for_help" do
          expect(response).to match_array(["Foot", "Public"])
        end
      end

      describe "with offer_help user" do
        let(:user) { create(:offer_help_user, address: address, travel_distance: 200) }

        it "returns outings with exclusive_to nil or offer_help" do
          expect(response).to match_array(["Ball", "Public"])
        end
      end

      describe "with user having association" do
        let(:user) { create(:partner_user, address: address, travel_distance: 200) }

        it "returns empty result when user has association" do
          response = OutingsServices::Finder.new(user, { q: q, interests: interests, interest_list: interest_list }).find_all.map(&:title)
          expect(response).to eq(["Foot", "Ball", "Public"])
        end
      end
    end
  end
end
