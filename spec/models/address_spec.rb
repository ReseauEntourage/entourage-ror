require 'rails_helper'
require 'mixpanel_tools'

RSpec.describe Address, type: :model do
  it { should validate_presence_of(:place_name) }
  it { should validate_presence_of(:latitude) }
  it { should validate_presence_of(:longitude) }
end
