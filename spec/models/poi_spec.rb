require 'rails_helper'

describe Poi, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_numericality_of(:latitude) }
  it { should validate_numericality_of(:longitude) }
  describe 'poi validation' do
    let!(:poi) { FactoryGirl.create :poi }
    subject { poi }
    context 'should succeed when the fields are not blank' do
      it { should be_valid }
    end
  end
end