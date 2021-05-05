require 'rails_helper'

describe Poi, :type => :model do
  it { should validate_presence_of(:name) }

  describe 'poi validation' do
    let!(:poi) { FactoryBot.create :poi }
    subject { poi }
    context 'should succeed when the fields are not blank' do
      it { should be_valid }
    end
  end

  describe 'poi validation' do
    context 'should not succeed when the categories are blank' do
      it {
        expect {
          FactoryBot.create :poi, category: nil, category_ids: []
        }.to raise_error (ActiveRecord::RecordInvalid)
      }
    end
  end

end
