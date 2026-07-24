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
      let(:action) { FactoryBot.create(:contribution, section: 'clothes', display_category: nil) }

      it { expect(serialized[:section]).to eq('clothes') }
    end

    context 'display_category is defined' do
      let(:action) { FactoryBot.create(:contribution, section: nil, display_category: 'resource') }

      it { expect(serialized[:section]).to eq('services') }
    end

    context 'section, display_category are defined (created in v7, updated in v8, accessed from v8)' do
      let(:action) { FactoryBot.create(:contribution, section: 'clothes', display_category: 'resource') }

      it { expect(serialized[:section]).to eq('clothes') }
    end

    context 'section_taggings is preloaded' do
      let(:action) {
        contribution = FactoryBot.create(:contribution, section: 'clothes', display_category: nil)
        Contribution.includes(section_taggings: :tag).find(contribution.id)
      }

      it 'reads the section from the preloaded taggings instead of querying section_list' do
        expect(action.association(:section_taggings).loaded?).to be true
        expect(action).not_to receive(:section_list)

        expect(serialized[:section]).to eq('clothes')
      end
    end
  end

  describe 'member' do
    let(:user) { FactoryBot.create(:public_user) }
    let(:action) { FactoryBot.create(:contribution) }

    let(:serialized) { V1::ActionSerializer.new(action, scope: { user: user }).serializable_hash }

    context 'user is a member' do
      before { FactoryBot.create(:join_request, joinable: action, user: user, status: JoinRequest::ACCEPTED_STATUS) }

      it { expect(serialized[:member]).to eq(true) }
    end

    context 'no user in scope' do
      before { FactoryBot.create(:join_request, joinable: action, user: user, status: JoinRequest::ACCEPTED_STATUS) }

      let(:serialized) { V1::ActionSerializer.new(action).serializable_hash }

      it { expect(serialized[:member]).to eq(false) }
    end

    context 'user is not a member' do
      it { expect(serialized[:member]).to eq(false) }
    end

    context 'join_requests is preloaded' do
      let(:action) {
        contribution = FactoryBot.create(:contribution)
        FactoryBot.create(:join_request, joinable: contribution, user: user, status: JoinRequest::ACCEPTED_STATUS)
        Contribution.includes(:join_requests).find(contribution.id)
      }

      it 'reads membership from the preloaded join_requests instead of querying member_ids' do
        expect(action.association(:join_requests).loaded?).to be true
        expect(action).not_to receive(:member_ids)

        expect(serialized[:member]).to eq(true)
      end
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
