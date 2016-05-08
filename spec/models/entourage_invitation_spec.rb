require 'rails_helper'

RSpec.describe EntourageInvitation, type: :model do
  it { expect(FactoryGirl.build(:entourage_invitation).save).to be true }
  it { should validate_presence_of :invitable }
  it { should validate_presence_of :inviter }
  it { should validate_presence_of :invitee }
  it { should validate_presence_of :phone_number }
  it { should validate_presence_of :invitation_mode }
  it { should validate_inclusion_of(:invitation_mode).in_array([EntourageInvitation::MODE_SMS]) }

  context "belongs to an entourage" do
    let(:entourage) { FactoryGirl.create(:entourage) }
    let(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitable: entourage) }
    it { expect(entourage.entourage_invitations).to eq([entourage_invitation]) }
  end

  context "create "

  context "belongs to a user" do
    let(:user) { FactoryGirl.create(:pro_user) }
    let(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitee: user) }
    it { expect(user.invitations).to eq([entourage_invitation]) }
  end

  describe "unique invitation by entourage" do
    let(:user) { FactoryGirl.create(:pro_user) }
    let(:entourage) { FactoryGirl.create(:entourage) }
    let!(:existing_entourage_invitation) { FactoryGirl.create(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33612345678") }
    it { expect(FactoryGirl.build(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33612345678").save).to be false}
    it { expect(FactoryGirl.build(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33699999999").save).to be true}
    it { expect(FactoryGirl.build(:entourage_invitation, inviter: user, phone_number: "+33612345678").save).to be true}
    it { expect(FactoryGirl.build(:entourage_invitation, invitable: entourage, phone_number: "+33612345678").save).to be true}
  end
end
