require 'rails_helper'

describe Api::V1::Entourages::UsersController do

  let(:user) { FactoryGirl.create(:user) }
  let(:entourage) { FactoryGirl.create(:entourage) }

  describe 'POST create' do
    context "signed in" do
      before { post :create, entourage_id: entourage.to_param, token: user.token }
      it { expect(entourage.users).to eq([user]) }
    end

  end
end