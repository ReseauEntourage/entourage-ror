require 'rails_helper'

describe SalesforceServices::Outing do
  describe "is_synchable?" do
    let(:user) { create :user, targeting_profile: :team, partner: create(:partner, staff: true) }
    let(:outing) { create(:outing, :outing_class, title: 'Papotage en ligne', online: true, user: user) }
    let(:result) { described_class.new(outing).is_synchable? }

    context "synchable" do
      it { expect(result).to eq(true) }
    end

    context "online" do
      let(:outing) { create(:outing, :outing_class, online: true, user: user) }

      it { expect(result).to eq(true) }
    end

    context "user is not team" do
      let(:user) { create :user, targeting_profile: :partner, partner: create(:partner) }

      it { expect(result).to eq(false) }
    end
  end
end
