require 'rails_helper'

RSpec.describe Partner, type: :model do
  it { expect(FactoryBot.build(:partner).save).to be true }
  it { should validate_presence_of :name }
  it { should validate_presence_of :address }
  it { should validate_presence_of :latitude }
  it { should validate_presence_of :longitude }
end
