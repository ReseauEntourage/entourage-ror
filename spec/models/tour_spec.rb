require 'rails_helper'

RSpec.describe Tour, :type => :model do
  
  describe 'tour validation' do

    context 'type is correct' do
      it "should be valid" do
        tour = FactoryGirl.build(:tour)
        expect(tour.valid?).to eq(true)
      end
    end

    context 'type is incorrect' do
      it "should be invalid" do
        tour = FactoryGirl.build(:tour, tour_type:"incorrect")
        expect(tour.valid?).to eq(false)
      end
    end

  end


end
