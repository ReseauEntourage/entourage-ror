require 'rails_helper'

RSpec.describe Category, :type => :model do
  it { should validate_presence_of(:name) }
  
  describe 'category validation' do
    let!(:category) { FactoryGirl.create :category }
    subject { new_category }
    context 'should fail with already existing name' do
      let(:new_category) { FactoryGirl.build :category }
      it { should_not be_valid }
    end
    context 'should succeed with new name' do
      let(:new_category) { FactoryGirl.build :category, name: "Hopital" }
      it { should be_valid }
    end
  end
end
