require 'rails_helper'
include AuthHelper

describe Admin::OptionsController do

  let!(:super_admin) { super_admin_basic_login }

  describe 'GET #index' do
    before { get :index }

    context 'has options' do
      let!(:option_list) { FactoryBot.create_list(:option, 2) }

      it { expect(assigns(:options).map(&:id)).to match_array(option_list.map(&:id)) }
    end

    context 'has no options' do
      it { expect(assigns(:options)).to eq([]) }
    end
  end

  describe 'PUT #update' do
    let!(:option) { FactoryBot.create(:option, active: true) }
    before { put :update, params: { id: option.id, option: { active: value } } }
    before { option.reload }

    shared_examples 'to inactive' do
      it { expect(option.active?).to eq(false) }
    end

    context 'to inactive with false' do
      let(:value) { false }
      include_examples 'to inactive'
    end

    context 'to inactive with string value' do
      let(:value) { '' }
      include_examples 'to inactive'
    end

    context 'to inactive with nil value' do
      let(:value) { nil }
      include_examples 'to inactive'
    end

    context 'to inactive with false string value' do
      let(:value) { 'false' }
      include_examples 'to inactive'
    end

    context 'stay active with random string' do
      let(:value) { 'foo' }
      it { expect(option.active?).to eq(true) }
    end
  end
end
