require 'rails_helper'

describe JoinRequestsServices::AdminAcceptedJoinRequestBuilder do

  context 'should create an accepted join request without invitation' do
    let(:entourage)      { FactoryBot.create(:entourage) }
    let(:admin_user)     { FactoryBot.create(:user, admin: true) }
    let(:non_admin_user) { FactoryBot.create(:user, admin: false) }

    it 'should be valid' do
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder.new(joinable: entourage, user: admin_user).create

      expect(Entourage.last.members.include?(User.last)).to be true
    end

    it 'should not be valid' do
      JoinRequestsServices::AdminAcceptedJoinRequestBuilder.new(joinable: entourage, user: non_admin_user).create

      expect(Entourage.last.members.include?(User.last)).to be false
    end

  end
end
