require 'rails_helper'
include CommunityHelper

describe Api::V1::FeedsController do
  let(:result) { JSON.parse(response.body) }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:user) { FactoryBot.create(:pro_user) }
      let!(:entourage) { FactoryBot.create(:entourage, updated_at: 4.hours.ago, created_at: 4.hours.ago, entourage_type: "ask_for_help") }
      let(:latitude) { entourage.latitude }
      let(:longitude) { entourage.longitude }
      let(:announcement) { FactoryBot.build(:announcement) }
      before do
        Storage::Bucket.any_instance.stub(:read_for) { "path/to/portrait_url" }
        allow_any_instance_of(FeedServices::AnnouncementsService)
          .to receive(:repositionned_announcements)
          .and_return([announcement])
      end

      context "get all" do
        before { get :index, params: { token: user.token, announcements: "v1", latitude: latitude, longitude: longitude } }
        it { expect(response.status).to eq(200) }
        it { expect(result).to eq({
          "feeds"=>[
            {
              "type"=>"Entourage",
              "data"=>{
                "id"=>entourage.id,
                "uuid"=>entourage.uuid_v2,
                "status"=>"open",
                "title"=>"Foobar",
                "group_type"=>"action",
                "public"=>false,
                "metadata"=>{"city"=>"", "display_address"=>""},
                "entourage_type"=>"ask_for_help",
                "display_category"=>"social",
                "postal_code"=>nil,
                "join_status"=>"not_requested",
                "number_of_unread_messages"=>0,
                "number_of_people"=>1,
                "author"=>{
                  "id"=>entourage.user.id,
                  "display_name"=>"John D.",
                  "avatar_url"=>nil,
                  "partner"=>nil,
                  "partner_role_title" => nil,
                },
                "location"=>{
                  "latitude"=>1.122,
                  "longitude"=>2.345
                },
                "created_at"=> entourage.created_at.iso8601(3),
                "updated_at"=> entourage.updated_at.iso8601(3),
                "description" => nil,
                "share_url"=>"#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
                "image_url"=>nil,
                "online"=>false,
                "event_url"=>nil,
                "display_report_prompt" => false
              },
              "heatmap_size" => 20
            },
            {
              "type"=>"Announcement",
              "data"=>{
                "id"=>1,
                "uuid"=>"1",
                "title"=>"Une autre façon de contribuer.",
                "body"=>"Entourage a besoin de vous pour continuer à accompagner les sans-abri.",
                "image_url"=>"path/to/portrait_url",
                "action"=>"Aider",
                "url"=>"http://test.host/api/v1/announcements/1/redirect/#{user.token}",
                "webapp_url"=>nil,
                "icon_url"=>"http://test.host/api/v1/announcements/1/icon",
                "author"=>nil
              }
            }
          ],
          "unread_count" => 0
        }) }
      end

      context "get entourages around location" do
        let!(:paris_entourage) { FactoryBot.create(:entourage, created_at: 4.hours.ago, updated_at: 4.hours.ago, latitude: 48.8566, longitude: 2.3522) }
        let!(:suburbs_entourage) { FactoryBot.create(:entourage, created_at: 5.hours.ago, updated_at: 5.hours.ago, latitude: 48.752552, longitude: 2.294402) }
        let!(:south_of_france) { FactoryBot.create(:entourage, created_at: 6.hours.ago, updated_at: 6.hours.ago, latitude: 43.716691, longitude: 7.258083) }

        context "default distance is 100" do
          before { get :index, params: { token: user.token, latitude: 48.8566, longitude: 2.3522 } }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id, suburbs_entourage.id]) }
        end

        context "10km distance" do
          before { get :index, params: { token: user.token, latitude: 48.8566, longitude: 2.3522, distance: 10 } }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id]) }
        end

        context "30km distance" do
          before { get :index, params: { token: user.token, latitude: 48.8566, longitude: 2.3522, distance: 30 } }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id, suburbs_entourage.id]) }
        end

        context "max distance is 40km" do
          before { get :index, params: { token: user.token, latitude: 48.8566, longitude: 2.3522, distance: 1000 } }
          it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([paris_entourage.id, suburbs_entourage.id]) }
        end
      end

      context "get entourages only" do
        before { get :index, params: { token: user.token, types: 'as', latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].count).to eq(1) }
        it { expect(result["feeds"][0]["type"]).to eq("Entourage") }
      end

      context "get entourages types only" do
        let!(:entourage_contribution) { FactoryBot.create(:entourage, created_at: 1.hour.ago, entourage_type: "contribution", latitude: latitude, longitude: longitude) }
        before { get :index, params: { token: user.token, types: "cs", latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_contribution.id]) }
      end

      context "get partners entourages only" do
        let(:partner_user) { create :partner_user }
        let!(:partner_entourage) { create(:entourage, latitude: latitude, longitude: longitude, user: partner_user) }
        before { get :index, params: { partners_only: 'true', token: user.token, latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([partner_entourage.id]) }
      end

      context "filter by timerange" do
        let!(:entourage1) { FactoryBot.create(:entourage, updated_at: 3.day.ago, created_at: 3.day.ago, latitude: latitude, longitude: longitude) }
        let!(:entourage2) { FactoryBot.create(:entourage, updated_at: 3.day.ago, created_at: 3.day.ago, latitude: latitude, longitude: longitude) }
        before { get :index, params: { token: user.token, time_range: 47, latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage.id]) }
      end

      context "public user doesn't see tours" do
        let(:public_user) { FactoryBot.create(:public_user) }
        before { get :index, params: { token: public_user.token, time_range: 47, latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage.id]) }
      end

      context "filter timerange" do
        let!(:my_entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago, status: :open, latitude: latitude, longitude: longitude) }
        let!(:my_old_entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 72.hour.ago, status: :open, latitude: latitude, longitude: longitude) }
        let!(:my_older_entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 50.hour.ago, created_at: 72.hour.ago, status: :open, latitude: latitude, longitude: longitude) }
        before { get :index, params: { token: user.token, types: 'as', time_range: 48, latitude: latitude, longitude: longitude } }
        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, entourage.id, my_old_entourage.id]) }
      end

      context "filter by status" do
        let!(:entourage) { nil } # ignore the top-level entourage for clarity

        let(:latitude) { entourage_open.latitude }
        let(:longitude) { entourage_open.longitude }

        let!(:entourage_open)        { create(:entourage, created_at: 1.hour.ago, status: :open) }
        let!(:entourage_closed)      { create(:entourage, created_at: 2.hour.ago, status: :closed, latitude: latitude, longitude: longitude) }
        let!(:entourage_blacklisted) { create(:entourage, created_at: 3.hour.ago, status: :blacklisted, latitude: latitude, longitude: longitude) }
        let!(:entourage_suspended)   { create(:entourage, created_at: 4.hour.ago, status: :suspended, latitude: latitude, longitude: longitude) }
        let!(:entourage_closed_success) do
          entourage = create(:entourage, :outcome_oui, created_at: 5.hour.ago, status: :closed, latitude: latitude, longitude: longitude)
          entourage
        end

        before { get :index, params: { token: user.token, latitude: latitude, longitude: longitude } }

        it { expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([entourage_open.id]) }
      end

      context "touch chat message association" do
        let!(:my_entourage) {
          FactoryBot.create(:entourage,
                             :joined,
                             join_request_user: user,
                             user: user,
                             updated_at: 3.hour.ago.beginning_of_hour,
                             created_at: 3.hour.ago.beginning_of_hour,
                             status: :open,
                             latitude: latitude,
                             longitude: longitude)
        }

        let!(:my_old_entourage) {
          FactoryBot.create(:entourage,
                             :joined,
                             join_request_user: user,
                             user: user,
                             updated_at: 24.hour.ago.beginning_of_hour,
                             created_at: 24.hour.ago.beginning_of_hour,
                             status: :open,
                             latitude: latitude,
                             longitude: longitude)
        }

        before do
          FactoryBot.create(:chat_message, messageable: my_old_entourage, created_at: DateTime.now, updated_at: DateTime.now, content: "foo")
          get :index, params: { token: user.token, time_range: 12, types: 'as', latitude: latitude, longitude: longitude }
        end

        it do
          expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, entourage.id, my_old_entourage.id])
        end
      end

      context "touch entourage invitation association" do
        let!(:my_entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 1.hour.ago, created_at: 1.hour.ago, status: :open, latitude: latitude, longitude: longitude) }
        let!(:my_old_entourage) { FactoryBot.create(:entourage, :joined, join_request_user: user, user: user, updated_at: 2.hour.ago, created_at: 24.hour.ago, status: :open, latitude: latitude, longitude: longitude) }
        let!(:entourage_invitation) { FactoryBot.create(:entourage_invitation, invitable: my_old_entourage, inviter: user, phone_number: "+40744219491") }
        before do
          EntourageServices::InvitationService.new(invitation: entourage_invitation).accept!
          get :index, params: { token: user.token, time_range: 48, types: 'as', latitude: latitude, longitude: longitude }
        end

        it do
          expect(result["feeds"].map {|feed| feed["data"]["id"]} ).to eq([my_entourage.id, entourage.id, my_old_entourage.id])
        end
      end
    end

    context "filter types" do
      let(:user) { create :public_user }
      let(:latitude) { 2.243 }
      let(:longitude) { 10.528 }

      def result_ids(params={})
        get :index, params: {token: user.token, latitude: latitude, longitude: longitude}.merge(params)
        result["feeds"].map {|feed| feed["data"]["id"] }
      end

      context "entourage" do
        with_community :entourage
        let!(:as) { create :entourage, entourage_type: :ask_for_help, display_category: :social, latitude: latitude, longitude: longitude }
        let!(:co) { create :entourage, entourage_type: :contribution, display_category: :other, latitude: latitude, longitude: longitude }

        it { expect(result_ids()).to eq [co.id, as.id] }
        it { expect(result_ids(types: 'as,co')).to eq [co.id, as.id] }
        it { expect(result_ids(types: 'as')).to eq [as.id] }
        it { expect(result_ids(types: 'contribution_other')).to eq [co.id] }
      end
    end

    context "page token" do
      let(:user) { create :public_user }
      let(:latitude) { 2.243 }
      let(:longitude) { 10.528 }
      let(:per_page) { :default }
      let!(:entourage_1) { create :entourage, created_at: 2.hours.ago, latitude: latitude,         longitude: longitude }
      let!(:entourage_2) { create :entourage, created_at: 1.hour.ago,  latitude: latitude + 0.001, longitude: longitude }
      let(:default_params) { {latitude: latitude, longitude: longitude} }
      let(:params) { default_params }

      def item_ids payload
        payload['feeds'].map { |f| f['data']['id'] }
      end

      describe "single-request tests" do
        before {
          FeedServices::FeedFinder.stub(:per) { per_page } if per_page != :default
          get :index, params: {token: user.token}.merge(params)
        }

        context "when no page token is given" do
          it { expect(item_ids(result)).to eq [entourage_2.id, entourage_1.id] }
        end

        context "when there is a next page" do
          let(:per_page) { 1 }
          it { expect(result['next_page_token']).to be_present }
        end

        context "when there is no next page" do
          let(:per_page) { 3 }
          it { expect(result).not_to have_key 'next_page_token' }
        end

        context "when the page token is invalid" do
          let(:params) { default_params.merge(page_token: 'some_invalid_token') }
          it { expect(response.status).to eq 400 }
          it { expect(result['message']).to eq 'Invalid page token.' }
        end

        context "when the page token is blank" do
          let(:params) { default_params.merge(page_token: ' ') }
          it { expect(item_ids(result)).to eq [entourage_2.id, entourage_1.id] }
        end
      end

      describe "multi-request tests" do
        let(:params) { default_params.merge(token: user.token) }
        before { FeedServices::FeedFinder.stub(:per) { 1 } }
        it do
          get :index, params: params
          page_1 = JSON.parse(response.body)
          expect(item_ids(page_1)).to eq [entourage_1.id]

          r = get :index, params: params.merge(page_token: result['next_page_token'])
          page_2 = JSON.parse(r.body)
          expect(item_ids(page_2)).to eq [entourage_2.id]
        end
      end
    end

    context "community support" do
      let(:user) { create :public_user }
      let(:latitude) { 3.853 }
      let(:longitude) { 43.997 }
      let!(:entourage_action) { create :entourage,    community: 'entourage', created_at: 1.hour.ago, updated_at: 1.hour.ago, latitude: latitude, longitude: longitude }
      let(:announcement) { build :announcement }
      before do
        allow_any_instance_of(FeedServices::AnnouncementsService)
          .to receive(:repositionned_announcements)
          .and_return([announcement])
      end
      before { get :index, params: { token: user.token, announcements: "v1", latitude: latitude, longitude: longitude } }

      context "signed in as an user from another community (entourage)" do
        with_community 'entourage'
        it { expect(response.status).to eq(200) }
        it { expect(result['feeds'].map { |f| [f['type'], f['data']['id']] }).to eq [['Entourage', entourage_action.id], ['Announcement', announcement.id]] }
      end
    end

    context "show past events" do
      let(:user) { create :public_user }
      let(:latitude) { 8.643 }
      let(:longitude) { 48.086 }
      let!(:past_outing) { create :outing, metadata: {starts_at: 5.hour.ago}, latitude: latitude, longitude: longitude }
      let!(:upcoming_outing) { create :outing, metadata: {starts_at: 1.hour.from_now}, latitude: latitude, longitude: longitude }
      let!(:custom_end_outing) { create :outing, metadata: {starts_at: 2.days.ago, ends_at: 3.hours.from_now}, latitude: latitude, longitude: longitude }

      def feeds(filters={})
        get :index, params: filters.merge(token: user.token, latitude: latitude, longitude: longitude)
        result["feeds"].map {|feed| feed["data"]["id"]}
      end

      it { expect(feeds).to eq [custom_end_outing.id, upcoming_outing.id] }
      it { expect(feeds(show_past_events: 'true')).to eq [custom_end_outing.id, upcoming_outing.id, past_outing.id] }
    end

    context "loginless" do
      let(:user) { AnonymousUserService.create_user $server_community }
      let!(:entourage) { create :entourage }
      let(:latitude) { entourage.latitude }
      let(:longitude) { entourage.longitude }
      let(:announcement) { build :announcement }

      before do
        allow_any_instance_of(FeedServices::AnnouncementsService)
          .to receive(:repositionned_announcements)
          .and_return([announcement])
      end

      before {
        Storage::Bucket.any_instance.stub(:read_for) { "path/to/portrait_url" }
        get :index, params: { token: user.token, latitude: latitude, longitude: longitude, announcements: :v1 }
      }
      it { expect(response.status).to eq(200) }
      it { expect(result).to eq({
        "feeds"=>[
          {"type"=>"Entourage",
           "data"=>{
             "id"=>entourage.id,
             "uuid"=>entourage.uuid_v2,
             "status"=>"open",
             "title"=>"Foobar",
             "group_type"=>"action",
             "public"=>false,
             "metadata"=>{"city"=>"", "display_address"=>""},
             "entourage_type"=>"ask_for_help",
             "display_category"=>"social",
             "postal_code"=>nil,
             "join_status"=>"not_requested",
             "number_of_unread_messages"=>0,
             "number_of_people"=>1,
             "created_at"=>entourage.created_at.iso8601(3),
             "updated_at"=>entourage.updated_at.iso8601(3),
             "description"=>nil,
             "share_url"=>"#{ENV['MOBILE_HOST']}/app/solicitations/#{entourage.uuid_v2}",
             "image_url"=>nil,
             "online"=>false,
             "event_url"=>nil,
             "author"=>{
               "id"=>entourage.user_id,
               "display_name"=>"John D.",
               "avatar_url"=>nil,
               "partner"=>nil,
               "partner_role_title" => nil,
             },
             "location"=>{
               "latitude"=>1.122,
               "longitude"=>2.345},
             "display_report_prompt" => false},
           "heatmap_size"=>20},
          {"type"=>"Announcement",
           "data"=>{
             "id"=>1,
             "uuid"=>"1",
             "title"=>"Une autre façon de contribuer.",
             "body"=>"Entourage a besoin de vous pour continuer à accompagner les sans-abri.",
             "image_url"=>"path/to/portrait_url",
             "action"=>"Aider",
             "url"=>"http://test.host/api/v1/announcements/1/redirect/#{user.token}",
             "webapp_url"=>nil,
             "icon_url"=>"http://test.host/api/v1/announcements/1/icon",
             "author"=>nil}}],
        "unread_count" => 0
    })}
    end
  end

  describe 'GET outings' do
    let(:user) { create :public_user }
    let(:params) { {} }
    let(:coordinates) { {latitude: 1, longitude: 1} }
    subject { get :outings, params: {token: user&.token}.merge(coordinates).merge(params) }

    context "not signed in" do
      let(:params) { {token: nil} }
      it { subject; expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:params) { {token: user.token} }
      it { subject; expect(response.status).to eq(200) }
    end

    context "missing param" do
      let(:params) { {latitude: nil} }
      it { subject; expect(response.status).to eq(400) }
    end

    it "excludes outings that have ended" do
      create :outing, {metadata: {starts_at: 4.hours.ago}}.merge(coordinates)
      create :outing, {metadata: {starts_at: 1.hour.ago, ends_at: 1.minute.ago}}.merge(coordinates)
      subject
      expect(result['feeds']).to eq []
    end

    it "includes outings that have not ended" do
      outing_1 = create :outing, {metadata: {starts_at: 2.hours.ago}}.merge(coordinates)
      outing_2 = create :outing, {metadata: {starts_at: 3.days.ago, ends_at: 1.minutes.from_now}}.merge(coordinates)
      subject
      expect(result['feeds'].map { |f| f['data']['id'] }).to eq [outing_2.id, outing_1.id]
    end

    it "orders results by start date" do
      outing_1 = create :outing, {metadata: {starts_at: 2.hours.from_now}}.merge(coordinates)
      outing_2 = create :outing, {metadata: {starts_at: 2.hours.ago}}.merge(coordinates)
      subject
      expect(result['feeds'].map { |f| f['data']['id'] }).to eq [outing_2.id, outing_1.id]
    end

    context "pagination" do
      let(:start_time) { 1.day.from_now.change(hour: 19, min: 30) }
      let!(:outing_1) { create :outing, {metadata: {starts_at: start_time}}.merge(coordinates) }
      let!(:outing_2) { create :outing, {metadata: {starts_at: start_time}}.merge(coordinates) }
      let(:params) { {starting_after: outing_1.uuid_v2} }

      it "supports pagination" do
        subject
        expect(result['feeds'].map { |f| f['data']['id'] }).to eq [outing_2.id]
      end
    end
  end
end
