require 'rails_helper'

RSpec.describe TourArea, type: :model do
  it { expect(FactoryBot.build(:tour_area).save!).to be true }

  it { should validate_presence_of(:area) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:email) }

  it { should validate_inclusion_of(:status).in_array(["active", "inactive"]) }
  it { should validate_numericality_of(:departement) }
end
