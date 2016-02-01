require 'rails_helper'

RSpec.describe EntouragesUser, type: :model do
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :entourage_id }
  it { should validate_presence_of :status }
  it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected"]) }
  it { should belong_to :user }
  it { should belong_to :entourage }

  it "validates uniqueness of entourages_user" do
    user = FactoryGirl.create(:public_user)
    entourage = FactoryGirl.create(:entourage)
    expect(EntouragesUser.new(user: user, entourage: entourage).save).to be true
    expect(EntouragesUser.new(user: user, entourage: entourage).save).to be false
  end
end
