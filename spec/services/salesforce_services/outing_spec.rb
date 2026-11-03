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

  describe "updatable_fields" do
    it { expect(described_class.new(build(:outing)).updatable_fields).to include(:event_url) }
  end

  describe "sync on event_url change" do
    let(:user) { create :user, targeting_profile: :team, partner: create(:partner, staff: true) }
    let!(:outing) { create(:outing, :outing_class, online: true, event_url: 'https://meet.google.com/abc', user: user, salesforce_id: 'sf-id') }

    before { allow(SalesforceJob).to receive(:perform_async) }

    it "updates the salesforce campaign" do
      outing.update!(event_url: 'https://meet.google.com/xyz')

      expect(SalesforceJob).to have_received(:perform_async).with('Outing', outing.id, 'update')
    end
  end
end
