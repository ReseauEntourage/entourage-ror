require 'rails_helper'

RSpec.describe Partner, type: :model do
  it { expect(FactoryBot.build(:partner).save).to be true }
  it { should validate_presence_of :name }
end
