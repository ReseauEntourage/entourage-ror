require 'rails_helper'

describe Api::V1::Users::NeighborhoodsController, :type => :controller do
  render_views

  let(:user) { FactoryBot.create(:pro_user) }
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not logged in" do
      before { get :index, params: { user_id: user.id } }
      it { expect(response.status).to eq(401) }
    end

    context "logged in" do
      let!(:neighborhood_created) { FactoryBot.create(:neighborhood, user: user, created_at: 1.day.ago) }
      let!(:neighborhood_joined) { FactoryBot.create(:neighborhood, user: user, created_at: 2.day.ago) }
      let!(:neighborhood_other) { FactoryBot.create(:neighborhood) }

      before { get :index, params: { user_id: user.id, token: user.token } }

      it { expect(response.status).to eq(200) }
      it { expect(result["neighborhoods"].count).to eq(2) }
      it { expect(result["neighborhoods"].map {|neighborhoods| neighborhoods["id"]}).to eq([neighborhood_created.id, neighborhood_joined.id]) }
    end
  end
end
