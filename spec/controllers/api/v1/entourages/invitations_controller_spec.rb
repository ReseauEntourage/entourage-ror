require 'rails_helper'

describe Api::V1::Entourages::InvitationsController do

  let(:user) { FactoryGirl.create(:pro_user) }
  let(:entourage) { FactoryGirl.create(:entourage) }

  describe 'POST create' do
    context "user not signed in" do
      before { post :create, entourage_id: entourage.to_param }
    end

    context "user signed in" do
      context "valid params" do
        before { post :create, entourage_id: entourage.to_param, invite: {mode: "SMS", phone_number: "+33612345678"}, token: user.token }
        it { expect(EntourageInvitation.count).to eq(1) }
      end
    end

  end
end