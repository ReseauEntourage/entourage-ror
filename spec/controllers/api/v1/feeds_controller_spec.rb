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
      let!(:tour) { FactoryGirl.create(:tour, updated_at: 5.hours.ago, created_at: 5.hours.ago, tour_type: "medical") }
      let!(:entourage) { FactoryGirl.create(:entourage, updated_at: 4.hours.ago, created_at: 4.hours.ago, entourage_type: "ask_for_help") }

      context "get all" do
        before { get :index, token: user.token, show_tours: "true" }
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
                                                     "updated_at"=> entourage.updated_at.iso8601(3),
                                                     "description" => nil
                                                 },
                                                 "heatmap_size" => 20
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
                                                         },
                                                         "updated_at"=>tour.updated_at.iso8601(3)
                                                     },
                                                    "heatmap_size" => 20
                                             }
        ]}) }
      end

      context "get entourages around location" do
        let!(:paris_entourage) { FactoryGirl.create(:entourage, updated_at: 4.hours.ago, latitude: 48.8566, longitude: 2.3522) }
        before { get :index, token: user.token, latitude: 48.8566, longitude: 2.3522 }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id]) }
      end

      context "get entourages only" do
        before { get :index, token: user.token, show_tours: "false" }
        it { expect(result["feeds"].count).to eq(1) }
        it { expect(result["feeds"][0]["type"]).to eq("Entourage") }
      end

      context "get tour types only" do
        let!(:tour_social) { FactoryGirl.create(:tour, updated_at: 2.hours.ago, created_at: 2.hours.ago, tour_type: "alimentary") }
        let!(:tour_medical) { FactoryGirl.create(:tour, updated_at: 3.hours.ago, created_at: 3.hours.ago, tour_type: "barehands") }
        before { get :index, token: user.token, show_tours: "true", tour_types: "alimentary, barehands" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([tour_social.id, tour_medical.id, entourage.id]) }
      end

      context "get entourages types only" do
        let!(:entourage_contribution) { FactoryGirl.create(:entourage, created_at: 1.hour.ago, entourage_type: "contribution") }
        before { get :index, token: user.token, entourage_types: "contribution" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_contribution.id]) }
      end


      context "show only my tours" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago) }
        let!(:entourage_i_joined) { FactoryGirl.create(:entourage, :joined, join_request_user: user, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_i_joined) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_not_requested) { FactoryGirl.create(:tour, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        before { get :index, token: user.token, show_tours: "true", show_my_tours_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id, tour_i_joined.id]) }
      end

      context "show only my entourages" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago) }
        let!(:entourage_not_requested) { FactoryGirl.create(:entourage, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_i_joined) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_i_created) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        before { get :index, token: user.token, show_tours: "true", show_my_entourages_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, tour_i_created.id, tour_i_joined.id]) }
      end

      context "show only my entourages and my tours" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago) }
        let!(:entourage_not_requested) { FactoryGirl.create(:entourage, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_i_joined) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_not_requested) { FactoryGirl.create(:tour, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        before { get :index, token: user.token, show_tours: "true", show_my_entourages_only: "true", show_my_tours_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, tour_i_joined.id]) }
      end

      context "filter by timerange" do
        let!(:entourage1) { FactoryGirl.create(:entourage, updated_at: 3.day.ago, created_at: 3.day.ago) }
        let!(:entourage2) { FactoryGirl.create(:entourage, updated_at: 3.day.ago, created_at: 3.day.ago) }
        let!(:tour2) { FactoryGirl.create(:tour, updated_at: 3.hours.ago, created_at: 3.hours.ago, tour_type: "medical") }
        before { get :index, token: user.token, show_tours: "true", time_range: 47 }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([tour2.id, entourage.id, tour.id]) }
      end

      context "public user doesn't see tours" do
        let(:public_user) { FactoryGirl.create(:public_user) }
        before { get :index, token: public_user.token, show_tours: "true", time_range: 47 }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage.id]) }
      end

      context "with before parameter" do
        let!(:old_tour) { FactoryGirl.create :tour, updated_at: 71.hours.ago }
        let!(:old_entourage) { FactoryGirl.create :entourage, updated_at: 72.hours.ago }
        before { get 'index', token: user.token, before: 2.day.ago.iso8601(3), show_tours: "true", format: :json }
        it { expect(JSON.parse(response.body)["feeds"].map{|feed| feed["data"]["id"]}).to eq([old_tour.id, old_entourage.id]) }
      end
    end
  end
end