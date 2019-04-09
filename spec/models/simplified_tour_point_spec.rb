require 'rails_helper'

describe SimplifiedTourPoint do
  it { expect(FactoryGirl.build(:simplified_tour_point).save).to be true }
  it { should validate_presence_of :longitude }
  it { should validate_presence_of :latitude }
  it { should validate_presence_of :tour_id }

  describe "passing time" do
    let(:point) { FactoryGirl.create(:simplified_tour_point) }
    it { expect(point.passing_time).to eq(point.created_at) }
  end
end
