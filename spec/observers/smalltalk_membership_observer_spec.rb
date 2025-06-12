require 'rails_helper'

describe SmalltalkMembershipObserver do
  let(:entourage_user) { create(:user) }

  describe "after create" do
    let!(:smalltalk) { create(:smalltalk) }
    let(:join_request) { create :join_request, joinable: smalltalk }

    before { User.stub(:find_entourage_user).and_return(entourage_user) }
    before { expect_any_instance_of(SmalltalkServices::MembershipMessager).to receive(:create_message).with(:new_member) }

    it { join_request }
  end

  describe "after update" do
    let!(:smalltalk) { create(:smalltalk) }
    let!(:join_request) { create :join_request, joinable: smalltalk }

    before { User.stub(:find_entourage_user).and_return(entourage_user) }
    before { expect_any_instance_of(SmalltalkServices::MembershipMessager).to receive(:create_message).with(:destroy_member) }

    it { join_request.update(status: :cancelled) }
  end
end
