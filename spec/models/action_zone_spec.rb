require 'rails_helper'

RSpec.describe ActionZone, type: :model do
  let(:zone) { build(:action_zone) }
  subject { zone.save }

  context "with country names" do
    let(:zone) { build(:action_zone, country: 'France') }

    it "converts country codes" do
      subject
      expect(zone.country).to eq 'FR'
    end
  end

  context "validation" do
    context "valid attributes" do
      it { is_expected.to be true }
    end

    context "invalid country code" do
      let(:zone) { build(:action_zone, country: 'DE') }
      it { is_expected.to be false }
    end

    context "invalid postal code length" do
      let(:zone) { build(:action_zone, postal_code: '1234') }
      it { is_expected.to be false }
    end
  end
end
