require 'rails_helper'

describe JoinRequestsServices::AdminAcceptedJoinRequestBuilder do

  context "should create an accepted join request without invitation" do
    let(:organization)   { FactoryBot.create(:organization) }
    let(:entourage)      { FactoryBot.create(:entourage) }
    let(:admin_user)     { FactoryBot.create(:user, admin: true, organization: organization) }
    let(:non_admin_user) { FactoryBot.create(:user, admin: false, organization: organization) }

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
