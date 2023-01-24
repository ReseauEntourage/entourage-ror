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

    context "people in paris: order by postal_code" do
      let(:paris) { create(:address, postal_code: '75001' )}
      let(:user) { create(:public_user, address: paris) }

      let!(:neighborhood_paris) { create(:neighborhood, zone: :ville, postal_code: '75020', latitude: 2, longitude: 2 ) }
      let!(:neighborhood_not_paris) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: paris.latitude, longitude: paris.longitude ) }

      it { expect(subject).not_to be_nil }
      it { expect(subject.id).to eq(neighborhood_paris.id) }
    end

    context "people not in paris: order by distance" do
      let(:nantes) { create(:address, postal_code: '44000' )}
      let(:user) { create(:public_user, address: nantes) }

      let!(:neighborhood_nantes) { create(:neighborhood, zone: :ville, postal_code: '44000', latitude: 2, longitude: 2 ) }
      let!(:neighborhood_15) { create(:neighborhood, zone: :ville, postal_code: '15000', latitude: nantes.latitude, longitude: nantes.longitude ) }

      it { expect(subject).not_to be_nil }
      it { expect(subject.id).to eq(neighborhood_15.id) } # this one because of coordinates
    end

    context "people in paris: order by distance if neighborhoods are not 'ville'" do
      let(:paris) { create(:address, postal_code: '75001' )}
      let(:user) { create(:public_user, address: paris) }

      let!(:neighborhood_paris) { create(:neighborhood, postal_code: '75020', latitude: 2, longitude: 2 ) }
      let!(:neighborhood_not_paris) { create(:neighborhood, postal_code: '15000', latitude: paris.latitude, longitude: paris.longitude ) }

      it { expect(subject).not_to be_nil }
      it { expect(subject.id).to eq(neighborhood_not_paris.id) } # this one because of coordinates
    end
  end
end
