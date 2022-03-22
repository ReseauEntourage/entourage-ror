require 'rails_helper'

RSpec.describe Neighborhood, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }

end
