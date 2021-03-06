require 'rails_helper'
include CommunityHelper

describe Api::V1::HomeController do

  let(:user) { FactoryBot.create(:offer_help_user) }
  let(:pro_user) { FactoryBot.create(:pro_user) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      # entourages
      let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: "open", latitude: 48.85436, longitude: 2.270340) }
      let!(:entourage_closed) { FactoryBot.create(:entourage, :joined, user: user, status: "closed", latitude: 48.85436, longitude: 2.270340) }
      # outings
      let!(:outing) { FactoryBot.create(:outing) }
      # announcements
      let!(:announcement) { FactoryBot.create(:announcement, user_goals: [:offer_help], areas: [:sans_zone]) }
      let!(:announcement_ask) { FactoryBot.create(:announcement, user_goals: [:ask_for_help], areas: [:sans_zone], id: 2) }
      # tours
      let!(:tour) { FactoryBot.create(:tour) }

      subject { JSON.parse(response.body) }

      it "renders json keys" do
        get :index, params: { token: user.token }

        expect(subject).to have_key("metadata")
        expect(subject).to have_key("headlines")
        expect(subject).to have_key("outings")
        expect(subject).to have_key("entourages")
      end

      it "renders entourages" do
        get :index, params: { token: user.token, latitude: 48.854367553784954, longitude: 2.270340589096274 }

        expect(subject["entourages"].count).to eq(1)
        expect(subject["entourages"]).to eq(
          [{
            "id" => entourage.id,
            "uuid"=>entourage.uuid_v2,
            "status"=>"open",
            "title"=>"Foobar",
            "group_type"=>"action",
            "public"=>false,
            "metadata"=>{"city"=>"", "display_address"=>""},
            "entourage_type"=>"ask_for_help",
            "display_category"=>"social",
            "postal_code"=>nil,
            "number_of_people"=>1,
            "author"=>{
              "id"=>entourage.user.id,
              "display_name"=>"John D.",
              "avatar_url"=>nil,
              "partner"=>nil,
              "partner_role_title" => nil
            },
            "location"=>{
              "latitude"=>48.85436,
              "longitude"=>2.270340
            },
            "join_status"=>"accepted",
            "number_of_unread_messages"=>0,
            "created_at"=> entourage.created_at.iso8601(3),
            "updated_at"=> entourage.updated_at.iso8601(3),
            "description" => nil,
            "share_url" => "https://app.entourage.social/actions/#{entourage.uuid_v2}",
            "image_url"=>nil,
            "online"=>false,
            "event_url"=>nil,
            "display_report_prompt" => false
          }]
        )
      end

      it "renders outings, no coordinate" do
        get :index, params: { token: user.token }

        expect(subject["outings"].count).to eq(0)
      end

      it "renders outings, with coordinate" do
        get :index, params: { token: user.token, latitude: 48.854367553784954, longitude: 2.270340589096274 }

        expect(subject["outings"].count).to eq(1)
      end

      it "renders announcements" do
        get :index, params: { token: user.token }

        expect(subject["headlines"]["metadata"]["order"]).to include("announcement_0")
        expect(subject["headlines"]["announcement_0"]["data"]).to eq(
          {
            "id" => announcement.id,
            "uuid" => "#{announcement.id}",
            "title" => "Une autre façon de contribuer.",
            "body" => "Entourage a besoin de vous pour continuer à accompagner les sans-abri.",
            "image_url" => nil,
            "action" => "Aider",
            "url" => "http://test.host/api/v1/announcements/#{announcement.id}/redirect/#{user.token}",
            "icon_url" => "http://test.host/api/v1/announcements/#{announcement.id}/icon",
            "author" => nil
          }
        )
      end
    end
  end
end
