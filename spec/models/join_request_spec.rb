require 'rails_helper'

RSpec.describe JoinRequest, type: :model do
  it { expect(FactoryGirl.build(:join_request).save).to be true }
  it { should belong_to :user }
  it { should belong_to :joinable }
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :joinable_id }
  it { should validate_presence_of :joinable_type }
  it { should validate_presence_of :status }
  it { should validate_inclusion_of(:status).in_array(["pending", "accepted", "rejected", "cancelled"]) }

  it "has unique join request per user and tour" do
    user = FactoryGirl.create(:pro_user)
    tour = FactoryGirl.create(:tour)
    expect(FactoryGirl.build(:join_request, user: user, joinable: tour).save).to be true
    expect(FactoryGirl.build(:join_request, user: user, joinable: tour).save).to be false
  end
end
