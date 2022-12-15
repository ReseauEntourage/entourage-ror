require 'rails_helper'

describe NeighborhoodServices::Joiner do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood) { FactoryBot.create(:neighborhood, id: 8) }

  let(:subject) { NeighborhoodServices::Joiner.new(user).join_default_beta_test! }

  describe "join_default_beta_test!" do
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

    context "existing join_request and accepted" do
      let(:join_request) { create :join_request, user: user, joinable: neighborhood, status: :accepted }

      before { join_request }

      it { expect(subject).to be_nil }
      it { expect { subject }.to change { JoinRequest.count }.by(0) }
    end
  end
end
