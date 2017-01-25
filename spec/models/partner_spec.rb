require 'rails_helper'

RSpec.describe Partner, type: :model do
  it { expect(FactoryGirl.build(:partner).save).to be true }
  it { should validate_presence_of :name }
  it { should validate_presence_of :large_logo_url }
  it { should validate_presence_of :small_logo_url }
end
