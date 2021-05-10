require 'rails_helper'
include CommunityHelper

describe Api::V1::EntouragesController do

  let(:user) { FactoryBot.create(:public_user) }
  before { ModerationServices.stub(:moderator) { nil } }

  describe 'GET index' do
    context "not signed in" do
      before { get :index }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:entourage) { FactoryBot.create(:entourage, :joined, user: user, status: "open") }
      subject { JSON.parse(response.body) }

      it "renders JSON response" do
        get :index, params: { token: user.token }
        expect(subject).to eq({
          "entourages"=> [{
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
              "latitude"=>1.122,
              "longitude"=>2.345
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
        })
      end

      context "no params" do
        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
      end

      context "order recents entourages" do
        let!(:entourage1) { FactoryBot.create(:entourage, updated_at: entourage.created_at - 2.hours, created_at: entourage.created_at - 2.hours) }
        let!(:entourage2) { FactoryBot.create(:entourage, updated_at: entourage.created_at - 3.days, created_at: entourage.created_at - 3.days) }
        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"].map{|h|h['id']}.sort).to eq([entourage.id, entourage1.id].sort) }
      end

      context "entourages made by other users" do
        let!(:another_entourage) { FactoryBot.create(:entourage, status: "open") }
        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(2) }
      end

      context "scope by visible state" do
        let!(:open_entourage)        { FactoryBot.create(:entourage, status: "open") }
        let!(:closed_entourage)      { FactoryBot.create(:entourage, status: "closed") }
        let!(:blacklisted_entourage) { FactoryBot.create(:entourage, status: "blacklisted") }

        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].map{ |e| e['id'] }).to match_array([entourage.id, open_entourage.id]) } # conflict
      end

      context "filter status" do
        let!(:closed_entourage) { FactoryBot.create(:entourage, status: "closed") }
        before { get :index, params: { status: "closed", token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(closed_entourage.id) }
      end

      # types
      context "filter entourage_type" do
        let!(:help_entourage) { FactoryBot.create(:entourage, entourage_type: "ask_for_help", display_category: "event", updated_at: entourage.created_at-1.hours, created_at: entourage.created_at-1.hours) }
        # before { get :index, types: "as, ae", token: user.token } # conflict
        before { get :index, params: { type: "ask_for_help", token: user.token } }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"].map{|h|h['id']}.sort).to eq([entourage.id, help_entourage.id].sort) }
      end

      context "filter wrong entourage_type" do
        let!(:help_entourage) { FactoryBot.create(:entourage, entourage_type: "ask_for_help", display_category: "event", updated_at: entourage.created_at-1.hours, created_at: entourage.created_at-1.hours) }
        before { get :index, params: { types: "cs, ce", token: user.token } }
        it { expect(subject["entourages"].count).to eq(0) }
      end

      # position
      context "filter position" do
        let!(:near_entourage) { FactoryBot.create(:entourage, latitude: 2.48, longitude: 40.5) }
        before { get :index, params: { latitude: 2.48, longitude: 40.5, token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(near_entourage.id) }
      end

      context "filter wrong position" do
        let!(:near_entourage) { FactoryBot.create(:entourage, latitude: 2.48, longitude: 40.5) }
        before { get :index, params: { latitude: 12.48, longitude: 40.5, token: user.token } }
        it { expect(subject["entourages"].count).to eq(0) }
      end

      # time_range
      context "filter time_range" do
        let!(:timed_entourage) { FactoryBot.create(:entourage, created_at: entourage.created_at - 2.hours) }
        before { get :index, params: { time_range: 24, token: user.token } } # default time_range
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"].map{|h|h['id']}.sort).to eq([entourage.id, timed_entourage.id].sort) }
      end

      context "filter wrong time_range" do
        let!(:timed_entourage) { FactoryBot.create(:entourage, created_at: entourage.created_at - 2.hours) }
        before { get :index, params: { time_range: 1, token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
      end

      # group_type
      context "filter group_type" do
        let!(:action_entourage) { FactoryBot.create(:entourage, group_type: :action) }
        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"].map{|h|h['id']}.sort).to eq([entourage.id, action_entourage.id].sort) }
      end

      context "filter group_type" do
        let!(:conversation_entourage) { FactoryBot.create(:entourage, group_type: :conversation) }
        before { get :index, params: { token: user.token } }
        it { expect(subject["entourages"].count).to eq(1) }
        it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
      end

      # sort
      context "sort by distance and created_at" do
        let!(:closest_entourage) { FactoryBot.create(:entourage, latitude: 2.4801, longitude: 40.5, created_at: entourage.created_at - 2.minutes) }
        let!(:middle_entourage) { FactoryBot.create(:entourage, latitude: 2.4802, longitude: 40.5, created_at: entourage.created_at - 1.minute) }
        let!(:farthest_entourage) { FactoryBot.create(:entourage, latitude: 2.4803, longitude: 40.5, created_at: entourage.created_at) }
        before { get :index, params: { per: 2, latitude: 2.48, longitude: 40.5, token: user.token } }
        it { expect(subject["entourages"].count).to eq(2) }
        it { expect(subject["entourages"].map{|h|h['id']}).to eq([middle_entourage.id, closest_entourage.id]) }
      end
    end
  end

  describe 'GET mine' do
    let!(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let(:other_user) { FactoryBot.create(:public_user) }
    subject { JSON.parse(response.body) }

    context "filter show_my_entourages_only" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "accepted") }

      before { get :mine, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(1) }
      it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
    end

    context "filter wrong user show_my_entourages_only" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: other_user, status: "accepted") }

      before { get :mine, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end

    context "filter wrong status show_my_entourages_only" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: "pending") }

      before { get :mine, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end
  end

  describe 'GET owns' do
    let(:other_user) { FactoryBot.create(:public_user) }
    subject { JSON.parse(response.body) }

    context "filter author" do
      let!(:entourage) { FactoryBot.create(:entourage, status: :open, user: user) }

      before { get :owns, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(1) }
      it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
    end

    context "filter wrong author" do
      let!(:entourage) { FactoryBot.create(:entourage, status: :open, user: other_user) }

      before { get :owns, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end
  end

  describe 'GET invitees' do
    let!(:entourage) { FactoryBot.create(:entourage, status: :open) }
    let(:other_user) { FactoryBot.create(:public_user) }
    subject { JSON.parse(response.body) }

    context "filter invitee" do
      let!(:entourage_invitations) { FactoryBot.create(:entourage_invitation, invitable: entourage, invitee: user, status: "accepted") }

      before { get :invitees, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(1) }
      it { expect(subject["entourages"][0]["id"]).to eq(entourage.id) }
    end

    context "filter wrong invitee invitee" do
      let!(:entourage_invitations) { FactoryBot.create(:entourage_invitation, invitable: entourage, invitee: other_user, status: "accepted") }

      before { get :invitees, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end

    context "filter wrong status invitee" do
      let!(:entourage_invitations) { FactoryBot.create(:entourage_invitation, invitable: entourage, invitee: user, status: "pending") }

      before { get :invitees, params: { token: user.token } }
      it { expect(subject["entourages"].count).to eq(0) }
    end
  end

  describe 'POST create' do
    context "not signed in" do
      before { post :create, params: { entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", display_category: "social" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      it "creates an entourage" do
        expect {
          post :create, params: { entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", display_category: "social" }, token: user.token }
        }.to change { Entourage.count }.by(1)
      end

      context "valid params" do
        before { allow_any_instance_of(EntourageServices::CategoryLexicon).to receive(:category) { "mat_help" } }
        before { post :create, params: { entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", display_category: "mat_help", description: "foo bar", category: "mat_help", recipient_consent_obtained: true}, token: user.token } }
        it { expect(JSON.parse(response.body)).to eq({
          "entourage"=> {
            "id"=>Entourage.last.id,
            "uuid"=>Entourage.last.uuid_v2,
            "status"=>"open",
            "title"=>"Foo",
            "group_type"=>"action",
            "public"=>false,
            "metadata"=>{"city"=>"", "display_address"=>""},
            "entourage_type"=>"ask_for_help",
            "display_category"=>"mat_help",
            "postal_code"=>nil,
            "number_of_people"=>1,
            "author"=>{
              "id"=>user.id,
              "display_name"=>"John D.",
              "avatar_url"=>nil,
              "partner"=>nil,
              "partner_role_title" => nil
            },
            "location"=>{
              "latitude"=>4.567,
              "longitude"=>1.123
            },
            "join_status"=>"accepted",
            "number_of_unread_messages"=>0,
            "created_at"=> Entourage.last.created_at.iso8601(3),
            "updated_at"=> Entourage.last.updated_at.iso8601(3),
            "description"=> "foo bar",
            "share_url" => "https://app.entourage.social/actions/#{Entourage.last.uuid_v2}",
            "image_url"=>nil,
            "online"=>false,
            "event_url"=>nil,
            "display_report_prompt" => false
          }
        })}
        it { expect(response.status).to eq(201) }
        it { expect(Entourage.last.longitude).to eq(1.123) }
        it { expect(Entourage.last.latitude).to eq(4.567) }
        it { expect(Entourage.last.number_of_people).to eq(1) }
        it { expect(Entourage.last.category).to eq("mat_help") }
        it { expect(Entourage.last.community).to eq("entourage") }
        it { expect(Entourage.last.public).to eq(false) }
        it { expect(user.entourage_participations).to eq([Entourage.last]) }
        it { expect(JoinRequest.count).to eq(1) }
        it { expect(JoinRequest.last.status).to eq(JoinRequest::ACCEPTED_STATUS) }

        context "community support" do
          with_community :pfp
          it { expect(response.status).to eq(400) }
          it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not create entourage", "reasons"=>["Group type n'est pas inclus(e) dans la liste"]}) }
        end
      end

      context "invalid params" do
        before { post :create, params: { entourage: { location: {longitude: "", latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", display_category: "social" }, token: user.token } }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not create entourage", "reasons"=>["Longitude doit être rempli(e)"]}) }
        it { expect(response.status).to eq(400) }
      end

      context "metadata (outings)" do
        let(:params) do
          {
            group_type: :outing,
            title: "Apéro Entourage",
            location: {
              latitude: 48.868959,
              longitude: 2.390185
            },
            metadata: {
              starts_at: "2018-09-04T19:30:00+02:00",
              place_name: "Le Dorothy",
              street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
              google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0"
            }
          }
        end
        before { post :create, params: { entourage: params, token: user.token } }
        it do
          outing = Entourage.last
          expect(JSON.parse(response.body)).to eq(
            "entourage"=>{
              "id"=>outing.id,
              "uuid"=>outing.uuid_v2,
              "status"=>"open",
              "title"=>"Apéro Entourage",
              "group_type"=>"outing",
              "public"=>false,
              "metadata"=>{
                "starts_at"=>"2018-09-04T19:30:00.000+02:00",
                "ends_at"=>"2018-09-04T22:30:00.000+02:00",
                "previous_at"=>nil,
                "place_name"=>"Le Dorothy",
                "street_address"=>"85 bis rue de Ménilmontant, 75020 Paris, France",
                "google_place_id"=>"ChIJFzXXy-xt5kcRg5tztdINnp0",
                "display_address"=>"Le Dorothy, 85 bis rue de Ménilmontant, 75020 Paris",
                "entourage_image_id"=>nil
              },
              "entourage_type"=>"contribution",
              "display_category"=>nil,
              "postal_code"=>nil,
              "join_status"=>"accepted",
              "number_of_unread_messages"=>0,
              "number_of_people"=>1,
              "created_at"=>outing.created_at.iso8601(3),
              "updated_at"=>outing.updated_at.iso8601(3),
              "description"=>nil,
              "share_url"=>"https://app.entourage.social/actions/#{outing.uuid_v2}",
              "image_url"=>nil,
              "online"=>false,
              "event_url"=>nil,
              "author"=>{
                "id"=>user.id,
                "display_name"=>"John D.",
                "avatar_url"=>nil,
                "partner"=>nil,
                "partner_role_title" => nil
              },
              "location"=>{
                "latitude"=>48.868959,
                "longitude"=>2.390185
              },
              "display_report_prompt" => false
            }
          )
        end
        it { expect(response.status).to eq(201) }
      end

      context "recipient consent" do
        let(:group_details) { {entourage_type: "ask_for_help"} }
        let(:entourage) { Entourage.last }
        let(:consent_obtained) { entourage.moderation&.action_recipient_consent_obtained }
        before { post :create, params: { entourage: group_details.merge(location: {longitude: 1.123, latitude: 4.567}, title: "foo", recipient_consent_obtained: recipient_consent_obtained), token: user.token } }

        context "missing param" do
          let(:recipient_consent_obtained) { nil }
          it { expect(entourage.status).to eq 'open' }
          it { expect(entourage.moderation).to be_nil }
        end

        context "consent not obtained" do
          let(:recipient_consent_obtained) { false }
          it { expect(Entourage.last.status).to eq 'suspended' }
          it { expect(consent_obtained).to eq 'Non' }
        end

        context "consent obtained" do
          let(:recipient_consent_obtained) { true }
          it { expect(Entourage.last.status).to eq 'open' }
          it { expect(consent_obtained).to eq 'Oui' }
        end

        context "not an ask_for_help action" do
          let(:group_details) { {entourage_type: "contribution"} }
          let(:recipient_consent_obtained) { nil }
          it { expect(Entourage.last.status).to eq 'open' }
          it { expect(entourage.moderation).to be_nil }
        end
      end
    end

    describe "welcome email" do
      subject { -> { post :create, params: { entourage: { location: {longitude: 1.123, latitude: 4.567}, title: "foo", entourage_type: "ask_for_help", display_category: "mat_help", description: "foo bar", category: "mat_help"}, token: user.token } } }
      context "user has no email" do
        let(:user) { create :public_user, email: nil }
        it { is_expected.to change { ActionMailer::Base.deliveries.count }.by 0 }
      end

      context "user has an email" do
        it { is_expected.to change { ActionMailer::Base.deliveries.count }.by 1 }
        it "sets email recipient" do
          subject.call
          email = ActionMailer::Base.deliveries.last
          expect(email.to).to eq [user.email]
        end
      end
    end

  end

  describe 'GET show' do
    let!(:entourage) { FactoryBot.create(:entourage) }

    context "not signed in" do
      before { get :show, params: { id: entourage.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "entourage exists" do
        context "find by id" do
          before { get :show, params: { id: entourage.to_param, token: user.token } }
          it { expect(JSON.parse(response.body)).to eq({
            "entourage"=> {
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
              "number_of_people"=>1,
              "author"=>{
                "id"=>entourage.user.id,
                "display_name"=>"John D.",
                "avatar_url"=>nil,
                "partner"=>nil,
                "partner_role_title" => nil
              },
              "location"=>{
                "latitude"=>1.122,
                "longitude"=>2.345
              },
              "join_status"=>"not_requested",
              "number_of_unread_messages"=>nil,
              "created_at"=> entourage.created_at.iso8601(3),
              "updated_at"=> entourage.updated_at.iso8601(3),
              "description" => nil,
              "share_url" => "https://app.entourage.social/actions/#{entourage.uuid_v2}",
              "image_url"=>nil,
              "online"=>false,
              "event_url"=>nil,
              "display_report_prompt" => false
            }
          })}
        end

        context "find by v1 uuid" do
          before { get :show, params: { id: entourage.uuid.to_param, token: user.token } }
          it { expect(JSON.parse(response.body)["entourage"]["id"]).to eq entourage.id }
        end

        context "find by v2 uuid" do
          before { get :show, params: { id: entourage.uuid_v2.to_param, token: user.token } }
          it { expect(JSON.parse(response.body)["entourage"]["id"]).to eq entourage.id }
        end

        context "find conversations by hash uuid" do
          with_community :pfp
          let!(:entourage) { nil }
          let!(:conversation) { create :conversation, participants: [user] }
          before { get :show, params: { id: conversation.uuid_v2.to_param, token: user.token } }
          it { expect(JSON.parse(response.body)["entourage"]["id"]).to eq conversation.id }
        end

        context "find a null conversations by list uuid" do
          with_community :pfp
          let!(:entourage) { nil }
          let(:other_user) { create :public_user, first_name: "Buzz", last_name: "Lightyear" }
          before { get :show, params: { id: "1_list_#{user.id}-#{other_user.id}", token: user.token } }
          it { expect(JSON.parse(response.body)).to eq({
            "entourage"=>{
              "id"=>nil,
              "uuid"=>"1_list_#{user.id}-#{other_user.id}",
              "status"=>"open",
              "title"=>"Buzz L.",
              "group_type"=>"conversation",
              "public"=>false,
              "metadata"=>{},
              "entourage_type"=>"contribution",
              "display_category"=>nil,
              "postal_code"=>nil,
              "join_status"=>"accepted",
              "number_of_unread_messages"=>0,
              "number_of_people"=>2,
              "created_at"=>nil,
              "updated_at"=>nil,
              "description"=>nil,
              "share_url"=>nil,
              "image_url"=>nil,
              "online"=>false,
              "event_url"=>nil,
              "author"=>{
                "id"=>other_user.id,
                "display_name"=>"Buzz L.",
                "avatar_url"=>nil,
                "partner"=>nil,
                "partner_role_title" => nil},
              "location"=>{"latitude"=>0.0, "longitude"=>0.0},
              "display_report_prompt" => false
            }
          })}
        end

        context "metadata" do
          with_community :pfp
          let!(:entourage) { nil }
          let(:starts_at) { 1.day.from_now.change(hour: 19, min: 30) }
          let!(:outing) { create :outing, metadata: {starts_at: starts_at} }
          before { get :show, params: { id: outing.id, token: user.token } }
          it { expect(JSON.parse(response.body)['entourage']).to include(
            "metadata"=>{
              "starts_at"=>starts_at.iso8601(3),
              "ends_at"=>(starts_at + 3.hours).iso8601(3),
              "previous_at"=>nil,
              "display_address"=>"Café la Renaissance, 44 rue de l’Assomption, 75016 Paris",
              "place_name"=>"Café la Renaissance",
              "street_address"=>"44 rue de l’Assomption, 75016 Paris, France",
              "google_place_id"=>"foobar",
              "entourage_image_id"=>nil
            }
          )}
        end

        context "last_message" do
          let!(:join_request) { create :join_request, joinable: entourage, user: user, status: :pending }
          before { get :show, params: { id: entourage.uuid.to_param, include_last_message: 'true', token: user.token } }
          it { expect(JSON.parse(response.body)["entourage"]["last_message"]).to eq(
            "text"=>"Votre demande est en attente.",
            "author"=>nil
          )}
        end
      end

      context "entourage doesn't exists" do
        it "return not found" do
          expect {
              get :show, params: { id: 0, token: user.token }
            }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      describe "create entourage display" do
        context "has distance and feed_rank and source" do
          before { get :show, params: { id: entourage.to_param, token: user.token, distance: 123.45, feed_rank: 2, source: "foo" } }
          it { expect(EntourageDisplay.count).to eq(1) }
          it { expect(EntourageDisplay.last.distance).to eq(123.45) }
          it { expect(EntourageDisplay.last.feed_rank).to eq(2) }
          it { expect(EntourageDisplay.last.source).to eq("foo") }
        end

        context "has distance and feed_rank but no source" do
          before { get :show, params: { id: entourage.to_param, token: user.token, distance: 123.45, feed_rank: 2 } }
          it { expect(EntourageDisplay.count).to eq(1) }
          it { expect(EntourageDisplay.last.distance).to eq(123.45) }
          it { expect(EntourageDisplay.last.feed_rank).to eq(2) }
          it { expect(EntourageDisplay.last.source).to be_nil }
        end

        context "no distance or feed_rank" do
          before { get :show, params: { id: entourage.to_param, token: user.token } }
          it { expect(EntourageDisplay.count).to eq(0) }
        end
      end
    end
  end

  describe 'PATCH update' do
    let!(:entourage) { FactoryBot.create(:entourage) }

    context "not signed in" do
      before { patch :update, params: { id: entourage.to_param, entourage: {title: "new_title"} } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let!(:user_entourage) { FactoryBot.create(:entourage, :joined, user: user) }

      context "entourage exists" do
        before { patch :update, params: { id: user_entourage.to_param, entourage: {title: "new_title"}, token: user.token } }
        it { expect(JSON.parse(response.body)).to eq({
          "entourage"=> {
            "id"=>user_entourage.id,
            "uuid"=>user_entourage.uuid_v2,
            "status"=>"open",
            "title"=>"New_title",
            "group_type"=>"action",
            "public"=>false,
            "metadata"=>{"city"=>"", "display_address"=>""},
            "entourage_type"=>"ask_for_help",
            "display_category"=>"social",
            "postal_code"=>nil,
            "number_of_people"=>1,
            "author"=>{
              "id"=>user.id,
              "display_name"=>"John D.",
              "avatar_url"=>nil,
              "partner"=>nil,
              "partner_role_title" => nil
            },
            "location"=>{
              "latitude"=>1.122,
              "longitude"=>2.345
            },
            "join_status"=>"accepted",
            "number_of_unread_messages"=>0,
            "created_at"=> user_entourage.created_at.iso8601(3),
            "updated_at"=> user_entourage.reload.updated_at.iso8601(3),
            "description" => nil,
            "share_url" => "https://app.entourage.social/actions/#{user_entourage.uuid_v2}",
            "image_url"=>nil,
            "online"=>false,
            "event_url"=>nil,
            "display_report_prompt" => false
          }
        })}
      end

      context "closing with outcome" do
        before { patch :update, params: { id: user_entourage.to_param, entourage: {status: 'closed', outcome: {success: success}}, token: user.token } }

        context "valid success value" do
          let(:success) { false }
          it { expect(response.code).to eq '200' }
          it { expect(user_entourage.reload.status).to eq 'closed' }
          it { expect(user_entourage.moderation.action_outcome).to eq('Non') }
          it { expect(JSON.parse(response.body)["entourage"]).to include(
                                                                    "status"=>"closed",
                                                                    "outcome"=>{
                                                                      "success"=>false
                                                                    }
                                                                  )}
          it { expect(user_entourage.chat_messages.last.attributes).to include(
            "content"=>"a clôturé l’action",
            "user_id"=>user.id,
            "message_type"=>"status_update",
            "metadata"=>{
              :$id=>"urn:chat_message:status_update:metadata",
              :status=>"closed",
              :outcome_success=>false
            }
          ) }
        end

        context "any string is a truthy success value" do
          let(:success) { 'lol' }
          it { expect(response.code).to eq '200' }
          it { expect(user_entourage.reload.status).to eq 'closed' }
          it { expect(user_entourage.moderation.action_outcome).to eq('Oui') }
          it { expect(JSON.parse(response.body)["entourage"]).to include(
                                                                    "status"=>"closed",
                                                                    "outcome"=>{
                                                                      "success"=>true
                                                                    }
                                                                  )}
          it { expect(user_entourage.chat_messages.last.attributes).to include(
            "content"=>"a clôturé l’action",
            "user_id"=>user.id,
            "message_type"=>"status_update",
            "metadata"=>{
              :$id=>"urn:chat_message:status_update:metadata",
              :status=>"closed",
              :outcome_success=>true
            }
          ) }
        end

        context "invalid success value" do
          let(:success) { '' }
          it { expect(response.code).to eq '400' }
          it { expect(user_entourage.reload.status).to eq 'open' }
          it { expect(user_entourage.moderation).to be_nil }
          it { expect(JSON.parse(response.body)).to eq("message"=>"Could not update entourage", "reasons"=>["outcome.success must be a boolean"]) }
        end
      end

      context "reopening" do
        let!(:user_entourage) { create :entourage, :joined, user: user, status: :closed }
        before { patch :update, params: { id: user_entourage.to_param, entourage: {status: 'open'}, token: user.token } }

        it { expect(response.code).to eq '200' }
        it { expect(user_entourage.chat_messages.last.attributes).to include(
          "content"=>"a rouvert l’action",
          "user_id"=>user.id,
          "message_type"=>"status_update",
          "metadata"=>{
            :$id=>"urn:chat_message:status_update:metadata",
            :status=>"open",
            :outcome_success=>nil
          }
        )}
      end

      context "entourage does not belong to user" do
        before { patch :update, params: { id: entourage.to_param, entourage: {title: "new_title"}, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "entourage doesn't exists" do
        it "return not found" do
          expect {
            patch :update, params: { id: 0, entourage: {title: "new_title"}, token: user.token }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "invalid params" do
        before { patch :update, params: { id: user_entourage.to_param, entourage: {status: "not exist"}, token: user.token } }
        it { expect(JSON.parse(response.body)).to eq({"message"=>"Could not update entourage", "reasons"=>["Status n'est pas inclus(e) dans la liste"]}) }
        it { expect(response.status).to eq(400) }
      end

      context "update location" do
        let!(:user_entourage) { FactoryBot.create(:entourage, user: user) }
        before { patch :update, params: { id: user_entourage.to_param, entourage: {location: {latitude: 10.5, longitude: 20.1}}, token: user.token } }
        it { expect(user_entourage.reload.latitude).to eq(10.5) }
        it { expect(user_entourage.reload.longitude).to eq(20.1) }
      end

      context "changing group type" do
        let!(:user_entourage) { FactoryBot.create(:entourage, user: user) }
        before { patch :update, params: { id: user_entourage.to_param, entourage: {group_type: :conversation}, token: user.token } }
        it "ignores the change" do
          expect(user_entourage.reload.group_type).to eq 'action'
        end
        it { expect(response.code).to eq '200' }
      end

      context "update outing starts_at" do
        let(:new_start) { 12.day.from_now.change(hour: 19, min: 30) }
        let!(:user_entourage) { create :outing, user: user }
        before { patch :update, params: { id: user_entourage.to_param, entourage: {metadata: {starts_at: new_start}}, token: user.token } }
        it { expect(user_entourage.reload.metadata[:ends_at]).to eq(new_start + 3.hours) }
      end
    end
  end

  describe "PUT read" do
    let!(:entourage) { FactoryBot.create(:entourage) }

    context "not signed in" do
      before { put :read, params: { id: entourage.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "user is accepted in entourage" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: JoinRequest::ACCEPTED_STATUS, last_message_read: old_date) }
      before { put :read, params: { id: entourage.to_param, token: user.token } }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to be > old_date }
    end

    context "user is not accepted in entourage" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: JoinRequest::PENDING_STATUS, last_message_read: old_date) }
      before { put :read, params: { id: entourage.to_param, token: user.token } }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to eq(old_date) }
    end
  end

  describe 'POST #report' do
    let(:reporting_user) { create :public_user }
    let(:reported_group) { create :entourage }
    let(:message) { "MESSAGE" }

    before { post 'report', params: { token: reporting_user.token, id: reported_group.id, entourage_report: {message: message} } }

    context "valid params" do
      it { expect(response.status).to eq 201 }
      it { expect(ActionMailer::Base.deliveries.count).to eq 1 }
    end

    context "missing message" do
      let(:message) { '' }
      it { expect(response.status).to eq 400 }
      it { expect(ActionMailer::Base.deliveries.count).to eq 0 }
    end
  end

  describe "DELETE report_prompt" do
    let!(:entourage) { FactoryBot.create(:entourage) }

    context "user is accepted in entourage" do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, report_prompt_status: :display, status: :accepted ) }
      before { delete :dismiss_report_prompt, params: { id: entourage.to_param, token: user.token } }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.report_prompt_status).to eq 'dismissed' }
    end
  end

end
