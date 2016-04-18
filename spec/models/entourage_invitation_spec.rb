require 'rails_helper'

RSpec.describe EntourageInvitation, type: :model do
  it { expect(FactoryGirl.build(:entourage_invitation).save).to be true }

  context "belongs to an entourage" do
    let(:entourage) { FactoryGirl.create(:entourage) }
    let(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitable: entourage) }
    it { expect(entourage.entourage_invitations).to eq([entourage_invitation]) }
  end

  context "belongs to a user" do
    let(:user) { FactoryGirl.create(:pro_user) }
    let(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
    it { expect(user.invitations).to eq([entourage_invitation]) }
  end
end
