require 'rails_helper'

describe NeighborhoodServices::Joiner do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { FactoryBot.create(:neighborhood, id: 8) }

  describe "join_default_neighborhood!" do
    let(:subject) { NeighborhoodServices::Joiner.new(user).join_default_neighborhood! }

    context "unexisting neighborhood with id 8" do
      it { expect(subject).to be_nil }
      it { expect { subject }.not_to change { JoinRequest.count } }
    end

    context "unexisting join_request" do
      before { neighborhood }

      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { JoinRequest.count }.by(1) }
    end

    context "existing join_request but not accepted" do
      let(:join_request) { create :join_request, user: user, joinable: neighborhood, status: :pending }

      before { join_request }

      it { expect(subject).to eq(true) }
      it { expect { subject }.to change { JoinRequest.count }.by(0) }
    end

    context "existing join_request and cancelled" do
      let(:join_request) { create :join_request, user: user, joinable: neighborhood, status: :cancelled }

      before { join_request }

      it { expect(subject).to be_nil }
      it { expect { subject }.to change { JoinRequest.count }.by(0) }
    end

    context "existing join_request and accepted" do
      let(:join_request) { create :join_request, user: user, joinable: neighborhood, status: :accepted }

      before { join_request }

      it { expect(subject).to be_nil }
      it { expect { subject }.to change { JoinRequest.count }.by(0) }
    end
  end

  describe "default_neighborhood" do
    let(:subject) { NeighborhoodServices::Joiner.new(user).default_neighborhood }

    context "people not in lille, lyon, marseille, paris, rennes: order by distance" do
      let(:nantes) { create(:address, postal_code: '44000' )}
      let(:user) { create(:public_user, address: nantes) }

      let!(:neighborhood_nantes) { create(:neighborhood, zone: :ville, postal_code: '44000', latitude: 2, longitude: 2 ) }
      let!(:neighborhood_15) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: nantes.latitude, longitude: nantes.longitude ) }

      it { expect(subject).not_to be_nil }
      it { expect(subject.id).to eq(neighborhood_15.id) } # this one because of coordinates
    end

    describe "lille" do
      let(:lille) { create(:address, postal_code: '59130' )}
      let(:user) { create(:public_user, address: lille) }

      context "people in lille: order by postal_code" do
        let!(:neighborhood_lille) { create(:neighborhood, zone: :ville, postal_code: '59800', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_lille) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: lille.latitude, longitude: lille.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_lille.id) }
      end

      context "people in lille: order by distance if neighborhoods are not 'ville'" do
        let!(:neighborhood_lille) { create(:neighborhood, postal_code: '59800', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_lille) { create(:neighborhood, postal_code: '15000', latitude: lille.latitude, longitude: lille.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_not_lille.id) } # this one because of coordinates
      end
    end

    describe "lyon" do
      let(:lyon) { create(:address, postal_code: '69003' )}
      let(:user) { create(:public_user, address: lyon) }

      context "people in lyon: order by postal_code" do
        let!(:neighborhood_lyon) { create(:neighborhood, zone: :ville, postal_code: '69007', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_lyon) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: lyon.latitude, longitude: lyon.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_lyon.id) }
      end

      context "people in lyon: order by distance if neighborhoods are not 'ville'" do
        let!(:neighborhood_lyon) { create(:neighborhood, postal_code: '69007', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_lyon) { create(:neighborhood, postal_code: '15000', latitude: lyon.latitude, longitude: lyon.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_not_lyon.id) } # this one because of coordinates
      end
    end

    describe "marseille" do
      let(:marseille) { create(:address, postal_code: '13003' )}
      let(:user) { create(:public_user, address: marseille) }

      context "people in marseille: order by postal_code" do
        let!(:neighborhood_marseille) { create(:neighborhood, zone: :ville, postal_code: '13015', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_marseille) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: marseille.latitude, longitude: marseille.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_marseille.id) }
      end

      context "people in marseille: order by distance if neighborhoods are not 'ville'" do
        let!(:neighborhood_marseille) { create(:neighborhood, postal_code: '13015', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_marseille) { create(:neighborhood, postal_code: '15000', latitude: marseille.latitude, longitude: marseille.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_not_marseille.id) } # this one because of coordinates
      end
    end

    describe "paris" do
      let(:paris) { create(:address, postal_code: '75001' )}
      let(:user) { create(:public_user, address: paris) }

      context "people in paris: order by postal_code" do
        let!(:neighborhood_paris) { create(:neighborhood, zone: :ville, postal_code: '75020', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_paris) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: paris.latitude, longitude: paris.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_paris.id) }
      end

      context "people in paris: order by distance if neighborhoods are not 'ville'" do
        let!(:neighborhood_paris) { create(:neighborhood, postal_code: '75020', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_paris) { create(:neighborhood, postal_code: '15000', latitude: paris.latitude, longitude: paris.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_not_paris.id) } # this one because of coordinates
      end
    end

    describe "rennes" do
      let(:rennes) { create(:address, postal_code: '35200' )}
      let(:user) { create(:public_user, address: rennes) }

      context "people in rennes: order by postal_code" do
        let!(:neighborhood_rennes) { create(:neighborhood, zone: :ville, postal_code: '35700', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_rennes) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: rennes.latitude, longitude: rennes.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_rennes.id) }
      end

      context "people in rennes: order by distance if neighborhoods are not 'ville'" do
        let!(:neighborhood_rennes) { create(:neighborhood, postal_code: '35700', latitude: 2, longitude: 2 ) }
        let!(:neighborhood_not_rennes) { create(:neighborhood, postal_code: '15000', latitude: rennes.latitude, longitude: rennes.longitude ) }

        it { expect(subject).not_to be_nil }
        it { expect(subject.id).to eq(neighborhood_not_rennes.id) } # this one because of coordinates
      end
    end
  end
end
