require 'rails_helper'

describe Api::V1::FeedsController do

  let(:result) { JSON.parse(response.body) }
  
  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryGirl.create(:pro_user) }
      let!(:tour) { FactoryGirl.create(:tour, created_at: 2.day.ago, tour_type: "medical") }
      let!(:entourage) { FactoryGirl.create(:entourage, created_at: 1.day.ago) }

      context "get all" do
        before { get :index, token: user.token, show_tours: true }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({"feeds"=>[{
                                                 "type"=>"Entourage",
                                                 "data"=>{
                                                     "id"=>entourage.id,
                                                     "status"=>"open",
                                                     "title"=>"foobar",
                                                     "entourage_type"=>"ask_for_help",
                                                     "join_status"=>"not_requested",
                                                     "number_of_unread_messages"=>nil,
                                                     "number_of_people"=>1,
                                                     "author"=>{
                                                         "id"=>entourage.user.id,
                                                         "display_name"=>"John",
                                                         "avatar_url"=>nil
                                                     },
                                                     "location"=>{
                                                         "latitude"=>1.122,
                                                         "longitude"=>2.345
                                                     },
                                                     "created_at"=> entourage.created_at.iso8601(3),
                                                     "description" => nil
                                                 }
                                             },
                                             {
                                                 "type"=>"Tour",
                                                 "data"=>
                                                     {
                                                         "id"=>tour.id,
                                                         "tour_type"=>"medical",
                                                         "status"=>"ongoing",
                                                         "vehicle_type"=>"feet",
                                                         "distance"=>0,
                                                         "organization_name"=>tour.organization_name,
                                                         "organization_description"=>"Association description",
                                                         "start_time"=>tour.created_at.iso8601(3),
                                                         "end_time"=>nil,
                                                         "number_of_people"=>1,
                                                         "join_status"=>"not_requested",
                                                         "number_of_unread_messages"=>nil,
                                                         "tour_points"=>[],
                                                         "author"=>{"id"=>tour.user.id,
                                                                    "display_name"=>"John",
                                                                    "avatar_url"=>nil
                                                         }
                                                     }
                                             }
        ]}) }
      end

      context "get entourages only" do
        before { get :index, token: user.token, show_tours: false }
        it { expect(result["feeds"].count).to eq(1) }
        it { expect(result["feeds"][0]["type"]).to eq("Entourage") }
      end

      context "get tour types only" do
        let!(:tour_social) { FactoryGirl.create(:tour, created_at: 2.day.ago, tour_type: "alimentary") }
        let!(:tour_medical) { FactoryGirl.create(:tour, created_at: 3.day.ago, tour_type: "barehands") }
        before { get :index, token: user.token, show_tours: true, tour_types: "alimentary, barehands" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage.id, tour_social.id, tour_medical.id]) }
      end
    end
  end
end