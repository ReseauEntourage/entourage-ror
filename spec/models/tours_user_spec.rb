require 'rails_helper'

RSpec.describe ToursUser, type: :model do
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :tour_id }
  it { should validate_presence_of :status }
  it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected"]) }
  it { should belong_to :user }
  it { should belong_to :tour }

  it "validates uniqueness of entourages_user" do
    user = FactoryGirl.create(:user)
    tour = FactoryGirl.create(:tour)
    expect(ToursUser.new(user: user, tour: tour).save).to be true
    expect(ToursUser.new(user: user, tour: tour).save).to be false
  end
end
