require 'rails_helper'

RSpec.describe Api::V1::Users::ToursController, :type => :controller do
  render_views

  describe 'GET index' do
    let!(:user) { FactoryGirl.create(:pro_user) }
    let!(:tour1) { FactoryGirl.create(:tour, user: user, updated_at: Date.parse("10/10/2010"), status: "ongoing") }
    let!(:tour2) { FactoryGirl.create(:tour, user: user, updated_at: Date.parse("09/10/2010"), status: "closed") }
    let!(:other_tours) { FactoryGirl.create(:tour) }

    context "without pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json }
      it { expect(response.status).to eq 200 }

      it "responds with tours" do
        get 'index', user_id: user.id, token: user.token, format: :json

        res = JSON.parse(response.body)
        expect(res).to eq({"tours"=>[
            {
               "id"=>tour1.id,
               "uuid"=>tour1.id.to_s,
               "tour_type"=>"medical",
               "status"=>"ongoing",
               "vehicle_type"=>"feet",
               "distance"=>0,
               "start_time"=>tour1.created_at.iso8601(3),
               "end_time"=>nil,
               "organization_name"=>tour1.user.organization.name,
               "organization_description"=>"Association description",
               "author"=>{
                   "id"=>tour1.user.id,
                   "display_name"=>"John D.",
                   "avatar_url"=>nil,
                   "partner"=>nil
               },
               "number_of_people"=> 1,
               "join_status"=>"not_requested",
               "tour_points"=>[],
               "number_of_unread_messages"=>nil,
               "updated_at"=>tour1.updated_at.iso8601(3)
            },
            {
               "id"=>tour2.id,
               "uuid"=>tour2.id.to_s,
               "tour_type"=>"medical",
               "status"=>"closed",
               "vehicle_type"=>"feet",
               "distance"=>0,
               "start_time"=>tour2.created_at.iso8601(3),
               "end_time"=>nil,
               "organization_name"=>tour2.user.organization.name,
               "organization_description"=>"Association description",
               "author"=>{
                   "id"=>tour2.user.id,
                   "display_name"=>"John D.",
                   "avatar_url"=>nil,
                   "partner"=>nil
               },
               "number_of_people"=> 1,
               "join_status"=>"not_requested",
               "tour_points"=>[],
               "number_of_unread_messages"=>nil,
               "updated_at"=>tour2.updated_at.iso8601(3)
            }]})
      end
    end

    context "with pagination params" do
      before { get 'index', user_id: user.id, token: user.token, format: :json, page: 1, per: 1 }
      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)["tours"].count).to eq 1 }
    end

    context "with location filter" do
      context "has tour around point" do
        let!(:tour_point) { FactoryGirl.create(:tour_point, tour: tour1, latitude: 48.2, longitude: 2.2) }
        before { get 'index', user_id: user.id, token: user.token, format: :json, distance: 1000, latitude: 48.2, longitude: 2.2 }
        it { expect(JSON.parse(response.body)["tours"].count).to eq 1 }
      end

      context "don't have any tour around point" do
        before { get 'index', user_id: user.id, token: user.token, format: :json, distance: 1000, latitude: 48.2, longitude: 2.2 }
        it { expect(JSON.parse(response.body)["tours"].count).to eq 0 }
      end
    end

    context "with status parameter" do
      before { get 'index', user_id: user.id, token: user.token, status: "ongoing", format: :json }
      it { expect(JSON.parse(response.body)["tours"].count).to eq(1) }
      it { expect(JSON.parse(response.body)["tours"].first["id"]).to eq(tour1.id) }
    end
  end
end
