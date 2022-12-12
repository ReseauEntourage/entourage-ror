require 'rails_helper'

describe V1::ActionSerializer do
  include ActiveModel::Serializers
  include ActiveModel::Serializers::JSON

  describe 'section' do
    let(:action) { FactoryBot.create(:contribution) }

    let(:serialized) { V1::ActionSerializer.new(action).serializable_hash }

    it { expect(serialized).to have_key(:section) }

    context 'section is not defined' do
      let(:action) { FactoryBot.create(:contribution, display_category: nil) }

      it { expect(serialized[:section]).to be_nil }
    end

    context 'section is defined' do
      let(:action) { FactoryBot.create(:contribution, section: "clothes", display_category: nil) }

      it { expect(serialized[:section]).to eq('clothes') }
    end

    context 'display_category is defined' do
      let(:action) { FactoryBot.create(:contribution, section: nil, display_category: "resource") }

      it { expect(serialized[:section]).to eq('services') }
    end

    context 'section, display_category are defined (created in v7, updated in v8, accessed from v8)' do
      let(:action) { FactoryBot.create(:contribution, section: "clothes", display_category: "resource") }

      it { expect(serialized[:section]).to eq('clothes') }
    end
  end
end
