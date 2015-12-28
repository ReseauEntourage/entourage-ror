require 'rails_helper'

RSpec.describe TourPoint, :type => :model do
  it { should belong_to :tour }
end
