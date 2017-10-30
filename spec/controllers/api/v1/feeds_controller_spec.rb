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
      let(:announcement) { FactoryGirl.build(:announcement, author: user) }
      before do
        allow_any_instance_of(FeedServices::AnnouncementsService)
          .to receive(:select_announcement)
          .and_return(announcement)
      end

      context "get all" do
        before { get :index, token: user.token, show_tours: "true", announcements: "v1" }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({"feeds"=>[{
                                                 "type"=>"Entourage",
                                                 "data"=>{
                                                     "id"=>entourage.id,
                                                     "status"=>"open",
                                                     "title"=>"foobar",
                                                     "entourage_type"=>"ask_for_help",
                                                     "display_category"=>"social",
                                                     "join_status"=>"not_requested",
                                                     "number_of_unread_messages"=>nil,
                                                     "number_of_people"=>1,
                                                     "author"=>{
                                                         "id"=>entourage.user.id,
                                                         "display_name"=>"John",
                                                         "avatar_url"=>nil,
                                                         "partner"=>nil
                                                     },
                                                     "location"=>{
                                                         "latitude"=>1.122,
                                                         "longitude"=>2.345
                                                     },
                                                     "created_at"=> entourage.created_at.iso8601(3),
                                                     "updated_at"=> entourage.updated_at.iso8601(3),
                                                     "description" => nil,
                                                     "share_url" => "http://entourage.social/entourages/#{entourage.uuid_v2}"

                                                 },
                                                 "heatmap_size" => 20
                                             },
                                             {
                                                 "type"=>"Announcement",
                                                 "data"=>{
                                                     "id"=>1,
                                                     "title"=>"Une autre façon de contribuer.",
                                                     "body"=>"Entourage a besoin de vous pour continuer à accompagner les sans-abri.",
                                                     "action"=>"Aider",
                                                     "url"=>"http://test.host/api/v1/announcements/1/redirect?token=#{user.token}",
                                                     "icon_url"=>"http://test.host/api/v1/announcements/1/icon",
                                                     "author"=>{
                                                         "id"=>announcement.author.id,
                                                         "display_name"=>"John",
                                                         "avatar_url"=>nil,
                                                         "partner"=>nil
                                                     }
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
                                                                    "avatar_url"=>nil,
                                                                    "partner"=>nil
                                                         },
                                                         "updated_at"=>tour.updated_at.iso8601(3)
                                                     },
                                                    "heatmap_size" => 20
                                             }
        ]}) }
      end

      context "get entourages around location" do
        let!(:paris_entourage) { FactoryGirl.create(:entourage, updated_at: 4.hours.ago, latitude: 48.8566, longitude: 2.3522) }
        let!(:suburbs_entourage) { FactoryGirl.create(:entourage, updated_at: 5.hours.ago, latitude: 48.752552, longitude: 2.294402) }
        let!(:south_of_france) { FactoryGirl.create(:entourage, updated_at: 6.hours.ago, latitude: 43.716691, longitude: 7.258083) }

        context "default distance" do
          before { get :index, token: user.token, latitude: 48.8566, longitude: 2.3522 }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id]) }
        end

        context "30km distance" do
          before { get :index, token: user.token, latitude: 48.8566, longitude: 2.3522, distance: 30 }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id, suburbs_entourage.id]) }
        end

        context "max distance is 40km" do
          before { get :index, token: user.token, latitude: 48.8566, longitude: 2.3522, distance: 1000 }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id, suburbs_entourage.id]) }
        end
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
        let!(:tour_not_requested_join_request) { FactoryGirl.create(:join_request, joinable: tour_not_requested, status: JoinRequest::ACCEPTED_STATUS) }
        before { get :index, token: user.token, show_tours: "true", show_my_tours_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, entourage_i_joined.id, tour_i_joined.id]) }
      end

      context "show only my entourages" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago) }
        let!(:entourage_not_requested) { FactoryGirl.create(:entourage, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:entourage_not_requested_join_request) { FactoryGirl.create(:join_request, joinable: entourage_not_requested, status: JoinRequest::ACCEPTED_STATUS) }
        let!(:tour_i_joined) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_i_created) { FactoryGirl.create(:tour, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        before { get :index, token: user.token, show_tours: "true", show_my_entourages_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, tour_i_created.id, tour_i_joined.id]) }
      end

      context "show only my entourages and my tours" do
        let!(:entourage_i_created) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago) }
        let!(:entourage_not_requested) { FactoryGirl.create(:entourage, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:entourage_not_requested_join_request) { FactoryGirl.create(:join_request, joinable: entourage_not_requested, status: JoinRequest::ACCEPTED_STATUS) }
        let!(:tour_i_joined) { FactoryGirl.create(:tour, :joined, join_request_user: user, updated_at: 3.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_not_requested) { FactoryGirl.create(:tour, updated_at: 2.hour.ago, created_at: 2.hour.ago) }
        let!(:tour_not_requested_join_request) { FactoryGirl.create(:join_request, joinable: tour_not_requested, status: JoinRequest::ACCEPTED_STATUS) }
        before { get :index, token: user.token, show_tours: "true", show_my_entourages_only: "true", show_my_tours_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_i_created.id, tour_i_joined.id]) }
      end

      context "show only my partner's entourages and tours" do
        let!(:partner) { FactoryGirl.create(:partner) }
        let!(:partner_user) { FactoryGirl.create(:pro_user) }
        let!(:partner_user_association) { FactoryGirl.create(:user_partner, user: partner_user, partner: partner, default: true) }
        let!(:current_user_association) { FactoryGirl.create(:user_partner, user: user, partner: partner, default: true) }
        let!(:other_user) { FactoryGirl.create(:pro_user) }
        let!(:entourage_by_partner) { FactoryGirl.create(:entourage, user: partner_user) }
        let!(:entourage_by_other) { FactoryGirl.create(:entourage, user: other_user) }
        let!(:tour_by_partner) { FactoryGirl.create(:tour, user: partner_user) }
        let!(:tour_by_other) { FactoryGirl.create(:tour, user: other_user) }
        before { get :index, token: user.token, show_tours: "true", show_my_partner_only: "true" }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([tour_by_partner.id, entourage_by_partner.id]) }
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
        before { get :index, token: user.token, before: 2.day.ago.iso8601(3), per: 10, show_tours: "true", format: :json }
        it { expect(JSON.parse(response.body)["feeds"].map{|feed| feed["data"]["id"]}).to eq([old_tour.id, old_entourage.id]) }
      end

      context "filter timerange" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago, status: :open) }
        let!(:my_old_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 24.hour.ago, status: :open) }
        let!(:my_older_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 3.hour.ago, created_at: 72.hour.ago, status: :open) }
        before { get :index, token: user.token, time_range: 48 }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, my_old_entourage.id, entourage.id]) }
      end

      context "touch chat message association" do
        let!(:my_entourage) {
          FactoryGirl.create(:entourage,
                             :joined,
                             join_request_user: user,
                             user: user,
                             updated_at: 3.hour.ago.beginning_of_hour,
                             created_at: 3.hour.ago.beginning_of_hour,
                             status: :open)
        }

        let!(:my_old_entourage) {
          FactoryGirl.create(:entourage,
                             :joined,
                             join_request_user: user,
                             user: user,
                             updated_at: 24.hour.ago.beginning_of_hour,
                             created_at: 24.hour.ago.beginning_of_hour,
                             status: :open)
        }

        before do
          FactoryGirl.create(:chat_message, messageable: my_old_entourage, created_at: DateTime.now, updated_at: DateTime.now, content: "foo")
          get :index, token: user.token, time_range: 48
        end

        it do
          expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_old_entourage.id, my_entourage.id, entourage.id])
        end
      end

      context "touch entourage invitation association" do
        let!(:my_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago, status: :open) }
        let!(:my_old_entourage) { FactoryGirl.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 24.hour.ago, status: :open) }
        let!(:entourage_invitation) { FactoryGirl.create(:entourage_invitation, invitable: my_old_entourage, inviter: user, phone_number: "+40744219491") }
        before do
          EntourageServices::InvitationService.new(invitation: entourage_invitation).accept!
          get :index, token: user.token, time_range: 48
        end

        it do
          expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_old_entourage.id, my_entourage.id, entourage.id])
        end
      end
    end
  end
end
