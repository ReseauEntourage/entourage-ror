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

  describe 'distance' do
    let(:latitude) { 0 }
    let(:longitude) { 0 }
    let(:options) { Hash.new }
    let(:action) { FactoryBot.create(:contribution, latitude: latitude, longitude: longitude) }

    let(:serialized) { V1::ActionSerializer.new(action, options).serializable_hash }

    it { expect(serialized).to have_key(:distance) }

    context 'no scope' do
      it { expect(serialized[:distance]).to be_nil }
    end

    context 'same place' do
      let(:options) {{
        scope: { latitude: 0, longitude: 0 }
      }}

      it { expect(serialized[:distance]).to eq(0.0) }
    end

    context 'different place' do
      let(:options) {{
        scope: { latitude: 0.01, longitude: 0.01 }
      }}

      it { expect(serialized[:distance]).to be_between(1.5, 1.6) }
    end

    context 'paris to nantes' do
      let(:latitude) { 48.87 }
      let(:longitude) { 2.33 }

      let(:options) {{
        scope: { latitude: 47.22, longitude: -1.55 }
      }}

      it { expect(serialized[:distance]).to be_between(340, 345) }
    end
  end
end
