require 'rails_helper'

RSpec.describe Partner, type: :model do
  it { expect(build(:partner).save).to be true }
  it { should validate_presence_of :name }
  it { should validate_presence_of :address }
  it { should validate_presence_of :latitude }
  it { should validate_presence_of :longitude }

  describe 'search_by' do
    context 'wrong search' do
      let!(:partner) { create(:partner, name: 'Foo') }
      it { expect(Partner.search_by('Foobar').pluck(:id)).to eq([]) }
      it { expect(Partner.search_by('Fooo').pluck(:id)).to eq([]) }
    end

    context 'trailing spaces' do
      let!(:partner) { create(:partner, name: 'Foo') }
      it { expect(Partner.search_by('Foo').pluck(:id)).to eq([partner.id]) }
      it { expect(Partner.search_by('  Foo  ').pluck(:id)).to eq([partner.id]) }
    end

    context 'with accent' do
      let!(:partner) { create(:partner, name: 'Féo') }
      it { expect(Partner.search_by('Féo').pluck(:id)).to eq([partner.id]) }
      it { expect(Partner.search_by('Feo').pluck(:id)).to eq([partner.id]) }
      it { expect(Partner.search_by('Fo').pluck(:id)).to eq([]) }
    end

    context 'with reversed accent' do
      let!(:partner) { create(:partner, name: 'Feo') }
      it { expect(Partner.search_by('Féo').pluck(:id)).to eq([partner.id]) }
      it { expect(Partner.search_by('Feo').pluck(:id)).to eq([partner.id]) }
      it { expect(Partner.search_by('Fo').pluck(:id)).to eq([]) }
    end
  end
end
