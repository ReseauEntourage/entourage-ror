require 'rails_helper'

RSpec.describe Category, :type => :model do

  let!(:category) { FactoryGirl.create :category }
  subject { new_category }

  describe 'category validation' do

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
