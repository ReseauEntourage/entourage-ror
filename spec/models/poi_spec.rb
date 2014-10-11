require 'rails_helper'

describe Poi, :type => :model do
  it { should validate_presence_of(:name) }

  describe 'poi validation' do
    let!(:poi) { FactoryGirl.create :poi }
    subject { poi }
    context 'should succeed with new email' do
      it { should be_valid }
    end
  end

end