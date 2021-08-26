require 'rails_helper'

RSpec.describe EntourageInvitation, type: :model do
  it { expect(FactoryBot.build(:entourage_invitation).save).to be true }
  it { should validate_presence_of :invitable_id }
  it { should validate_presence_of :inviter }
  it { should validate_presence_of :phone_number }
  it { should validate_presence_of :invitation_mode }
  it { should validate_inclusion_of(:invitation_mode).in_array([EntourageInvitation::MODE_SMS]) }

  context "belongs to an entourage" do
    let(:entourage) { FactoryBot.create(:entourage) }
    let(:entourage_invitation) { FactoryBot.create(:entourage_invitation, invitable: entourage) }
    it { expect(entourage.entourage_invitations).to eq([entourage_invitation]) }
  end

  context "belongs to a user" do
    let(:user) { FactoryBot.create(:pro_user) }
    let(:entourage_invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }
    it { expect(user.invitations).to eq([entourage_invitation]) }
  end

  describe "unique invitation by entourage" do
    let(:user) { FactoryBot.create(:pro_user) }
    let(:entourage) { FactoryBot.create(:entourage) }
    let!(:existing_entourage_invitation) { FactoryBot.create(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33612345678") }
    it { expect(FactoryBot.build(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33612345678").save).to be false}
    it { expect(FactoryBot.build(:entourage_invitation, inviter: user, invitable: entourage, phone_number: "+33699999999").save).to be true}
    it { expect(FactoryBot.build(:entourage_invitation, inviter: user, phone_number: "+33612345678").save).to be true}
    it { expect(FactoryBot.build(:entourage_invitation, invitable: entourage, phone_number: "+33612345678").save).to be true}
  end

  context "SMS" do
    let(:error_messages) { build(:entourage_invitation, invitee: nil).tap(&:save).errors.messages }
    it { expect(error_messages).to eq(
      invitee: ["doit être rempli(e)"]
    )}
  end

  context "good_waves" do
    let(:error_messages) { build(:entourage_invitation, invitation_mode: :good_waves, metadata: metadata).tap(&:save).errors.messages }

    context "no metadata" do
      let(:metadata) { {} }
      it { expect(error_messages).to eq(
        metadata: ["did not contain a required property of 'name'",
                   "did not contain a required property of 'email'"]
      )}
    end

    context "null metadata values" do
      let(:metadata) { {name:nil, email:nil} }
      it { expect(error_messages).to eq(
        metadata: ["'name' of type null did not match the following type: string"]
      )}
    end
  end
end
