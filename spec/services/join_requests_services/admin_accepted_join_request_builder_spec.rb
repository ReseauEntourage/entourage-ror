require 'rails_helper'

describe JoinRequestsServices::AdminAcceptedJoinRequestBuilder do

  context "should create an accepted join request without invitation" do
    let(:organization)   { FactoryGirl.create(:organization) }
    let(:entourage)      { FactoryGirl.create(:entourage) }
    let(:admin_user)     { FactoryGirl.create(:user, admin: true, organization: organization) }
    let(:non_admin_user) { FactoryGirl.create(:user, admin: false, organization: organization) }

    it "should be valid" do
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder.new(joinable: entourage, user: admin_user).create

      expect(Entourage.last.members.include?(User.last)).to be true
    end

    it "should not be valid" do
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder.new(joinable: entourage, user: non_admin_user).create

      expect(Entourage.last.members.include?(User.last)).to be false
    end

  end
end
