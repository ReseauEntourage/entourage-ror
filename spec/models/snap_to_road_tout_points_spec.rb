require 'rails_helper'

RSpec.describe SnapToRoadTourPoint, :type => :model do
  describe 'create' do
    it { should validate_presence_of(:longitude) }
    it { should validate_presence_of(:latitude) }
    it { should validate_presence_of(:tour_id) }
    it { should belong_to(:tour) }
  end
end