require 'rails_helper'

RSpec.describe UserPartner, type: :model do
  it { should validate_presence_of :user_id }
  it { should validate_presence_of :partner_id }
  it { should belong_to :partner }
  it { should belong_to :user }

  describe "Unique partner per user" do
    let(:user) { FactoryGirl.create(:public_user) }
    let(:partner) { FactoryGirl.create(:partner) }
    before { UserPartner.create!(user: user, partner: partner) }
    it { expect(UserPartner.new(user: user, partner: partner).save).to be false}
  end
end
