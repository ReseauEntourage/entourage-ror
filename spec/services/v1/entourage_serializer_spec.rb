require 'rails_helper'

describe V1::EntourageSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'author partner' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:partner) { FactoryBot.create(:partner) }
    let(:creator) { FactoryBot.create(:public_user, partner: partner) }
    let(:entourage) { FactoryBot.create(:entourage, user: creator) }
    let(:serialization) { V1::EntourageSerializer.new(entourage, scope: {
      user: user
    })}

    it { expect(serialization.author).to have_key(:id) }
    it { expect(serialization.author).to have_key(:display_name) }
    it { expect(serialization.author).to have_key(:avatar_url) }
    it { expect(serialization.author).to have_key(:partner) }
    it { expect(serialization.author).to have_key(:partner_role_title) }

    context 'user with no partner' do
      it { expect(serialization.author[:partner]).to have_key(:following) }
      it { expect(serialization.author[:partner][:following]).to be(false) }
    end

    context 'user with partner' do
      let!(:following) { FactoryBot.create(:following, partner: partner, user: user )}

      it { expect(serialization.author[:partner]).to have_key(:following) }
      it { expect(serialization.author[:partner][:following]).to be(true) }
    end
  end

  describe "display_category" do
    let(:entourage) { FactoryBot.create(:entourage) }
    let(:serialized) { V1::EntourageSerializer.new(entourage, scope: {}).serializable_hash }

    it { expect(serialized).to have_key(:display_category) }

    context "display_category is not defined" do
      let(:entourage) { FactoryBot.create(:entourage, display_category: nil) }

      it { expect(serialized[:display_category]).to be_nil }
    end

    context "display_category is defined" do
      let(:entourage) { FactoryBot.create(:entourage, display_category: "resource") }

      it { expect(serialized[:display_category]).to eq("resource") }
    end

    context "section is defined" do
      # simulates an action created from v8
      let!(:contribution) { FactoryBot.create(:contribution, display_category: nil, section: "clothes") }
      # but accessed from v7
      let(:entourage) { Entourage.find(contribution.id) }

      it { expect(serialized[:display_category]).to eq("mat_help") }
    end

    context "display_category, section are defined (created in v7, updated in v8, accessed from v7)" do
      # simulates an action created from v7, updated in v8
      let!(:contribution) { FactoryBot.create(:contribution, display_category: "resource", section: "clothes") }
      # but accessed from v7
      let(:entourage) { Entourage.find(contribution.id) }

      it { expect(serialized[:display_category]).to eq("resource") }
    end
  end
end
