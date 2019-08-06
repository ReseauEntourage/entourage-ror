require 'rails_helper'

describe Onboarding::V1 do
  let(:entourage) { create :entourage, :joined }
  let(:user) { create :public_user }
  let(:join_request) { build :join_request, joinable: entourage, user: user }
  let!(:moderator) { create :admin_user }

  before do
    Onboarding::V1.stub(:is_onboarding?) { true }
    Experimental::AutoAccept.stub(:enable_callback) { true }
  end

  it do
    expect(entourage.auto_accept_join_requests?).to be true
  end

  it "triggers an auto accept" do
    expect(Experimental::AutoAccept).to receive(:accept).with(join_request)
    join_request.save!
  end
end
