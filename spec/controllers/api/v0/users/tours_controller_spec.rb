require 'rails_helper'

RSpec.describe Api::V0::Users::ToursController, :type => :controller do
  render_views

  describe 'GET index' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:user_tours) { FactoryGirl.create_list(:tour, 3, user: user) }
    let!(:other_tours) { FactoryGirl.create(:tour) }

    context "without pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)["tours"].count).to eq 3 }
    end

    context "with pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json, page: 1, per: 1 }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)["tours"].count).to eq 1 }
    end
  end
end