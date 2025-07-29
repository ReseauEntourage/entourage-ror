require 'rails_helper'

describe Api::V1::Users::ActionsController, type: :controller do
  render_views

  let(:user) { FactoryBot.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not logged in" do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      let!(:action_created) { FactoryBot.create(:contribution, user: user, created_at: 1.day.ago) }
      let!(:action_joined) { FactoryBot.create(:contribution, user: user, created_at: 2.day.ago) }
      let!(:action_closed) { FactoryBot.create(:contribution, user: user, created_at: 3.day.ago, status: :closed) }
      let!(:action_other) { FactoryBot.create(:contribution) }

      before { get :index, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result["actions"].count).to eq(2) }
      it { expect(result["actions"].map {|actions| actions["id"]}).to eq([action_created.id, action_joined.id]) }
    end
  end
end
