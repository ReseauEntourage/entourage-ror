require 'rails_helper'

RSpec.describe Option, type: :model do
  it { should validate_presence_of :key }

  describe 'active?' do
    context 'active' do
      let!(:option) { FactoryBot.create(:option, key: :foo, active: true) }
      it { expect(Option.active? :foo).to eq(true) }
    end

    context 'inactive' do
      let!(:option) { FactoryBot.create(:option, key: :foo, active: false) }
      it { expect(Option.active? :foo).to eq(false) }
    end

    context 'inexistant' do
      it { expect(Option.active? :foo).to eq(false) }
    end
  end
end
