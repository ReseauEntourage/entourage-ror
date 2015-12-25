require 'rails_helper'

RSpec.describe TourPoint, :type => :model do
  it { should validate_numericality_of :latitude }
  it { should validate_numericality_of :longitude }
  it { should belong_to :tour }
end
