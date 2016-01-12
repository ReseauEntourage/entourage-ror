require 'rails_helper'

RSpec.describe Api::V1::Users::ToursController, :type => :controller do
  render_views

  describe 'GET index' do
    let!(:user) { FactoryGirl.create(:user) }
    let!(:tour1) { FactoryGirl.create(:tour, user: user, updated_at: Date.parse("10/10/2010")) }
    let!(:tour2) { FactoryGirl.create(:tour, user: user, updated_at: Date.parse("09/10/2010")) }
    let!(:other_tours) { FactoryGirl.create(:tour) }

    context "without pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json }
      it { expect(response.status).to eq 200 }

      it "responds with tours" do
        Timecop.freeze(DateTime.parse("10/10/2010").at_beginning_of_day)

        get 'index', user_id: user.id, token: user.token, format: :json

        res = JSON.parse(response.body)
        expect(res).to eq({"tours"=>[
            {"id"=>tour1.id,
             "tour_type"=>"medical",
             "status"=>"ongoing",
             "vehicle_type"=>"feet",
             "distance"=>0,
             "start_time"=>nil,
             "end_time"=>nil,
             "organization_name"=>tour1.user.organization.name,
             "organization_description"=>"Association description",
             "user_id"=>tour1.user_id,
             "tour_points"=>[]},
            {"id"=>tour2.id,
             "tour_type"=>"medical",
             "status"=>"ongoing",
             "vehicle_type"=>"feet",
             "distance"=>0,
             "start_time"=>nil,
             "end_time"=>nil,
             "organization_name"=>tour2.user.organization.name,
             "organization_description"=>"Association description",
             "user_id"=>tour2.user_id,
             "tour_points"=>[]}]})
      end
    end

    context "with pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json, page: 1, per: 1 }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)["tours"].count).to eq 1 }
    end
  end
end