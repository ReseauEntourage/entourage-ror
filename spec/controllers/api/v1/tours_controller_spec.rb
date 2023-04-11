require 'rails_helper'

RSpec.describe Api::V1::ToursController, :type => :controller do
  render_views

  describe "GET index" do

    let!(:user) { FactoryBot.create :pro_user }
    let(:date) { Date.parse("10/10/2010") }
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }

    context "without parameter" do
      before(:each) do
        11.times do |i|
          FactoryBot.create :tour, updated_at:date+i.hours
        end
      end

      before { get 'index', params: { token: user.token, format: :json } }

      it { expect(response.status).to eq 200 }
      it { expect(assigns(:tours).count).to eq(10) }
      it { expect(assigns(:tours).all? {|t| t.updated_at >= Date.parse("10/10/2010").at_beginning_of_day }).to be true }
    end

    it "responds with tours" do
      Timecop.freeze(DateTime.parse("10/10/2010").at_beginning_of_day)
      tours = FactoryBot.create_list :tour, 2

      get 'index', params: { token: user.token, format: :json }

      res = JSON.parse(response.body)
      expect(res).to eq({
        "tours" => [{
          "id" => tours.first.id,
          "uuid" => tours.first.id.to_s,
          "tour_type" => "medical",
          "status" => "ongoing",
          "vehicle_type" => "feet",
          "distance" => 0,
          "start_time" => tours.first.created_at.iso8601(3),
          "end_time" => nil,
          "organization_name" => tours.first.user.organization.name,
          "organization_description" => "Association description",
          "author" => {
            "id" => tours.first.user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "partner" => nil
          },
          "number_of_people" => 1,
          "join_status" => "not_requested",
          "tour_points" => [],
          "number_of_unread_messages" => 0,
          "updated_at" => tours.first.updated_at.iso8601(3)
        }, {
          "id" => tours.last.id,
          "uuid" => tours.last.id.to_s,
          "tour_type" => "medical",
          "status" => "ongoing",
          "vehicle_type" => "feet",
          "distance" => 0,
          "start_time" => tours.last.created_at.iso8601(3),
          "end_time" => nil,
          "organization_name" => tours.last.user.organization.name,
          "organization_description" => "Association description",
          "author" => {
            "id" => tours.last.user.id,
            "display_name" => "John D.",
            "avatar_url" => nil,
            "partner" => nil
          },
          "number_of_people" =>  1,
          "join_status" => "not_requested",
          "tour_points" => [],
          "number_of_unread_messages" => 0,
          "updated_at" => tours.last.updated_at.iso8601(3)
        }
      ]})
    end

    context "with limit parameter" do
      before(:each) do
        3.times do |i|
          FactoryBot.create :tour, updated_at:date+i.days
        end
      end

      it "returns limit tours" do
        get 'index', params: { token: user.token, per: 2, :format => :json }
        expect(JSON.parse(response.body)["tours"].count).to eq(2)
      end
    end

    context "with type parameter" do

      let!(:tour1) { FactoryBot.create :tour, tour_type:'medical' }
      let!(:tour2) { FactoryBot.create :tour, tour_type:'medical' }
      let!(:tour3) { FactoryBot.create :tour, tour_type:'alimentary' }
      let!(:tour4) { FactoryBot.create :tour, tour_type:'alimentary' }
      let!(:tour5) { FactoryBot.create :tour, tour_type:'medical' }

      it "returns status 200" do
        get 'index', params: { token: user.token, type:'alimentary', :format => :json }
        expect(response.status).to eq 200
      end

      it "returns only matching type tours" do
        get 'index', params: { token: user.token, type:'alimentary', :format => :json }
        expect(assigns(:tours)).to match_array([tour4, tour3])
      end

    end

    context "with vehicle type parameter" do

      let!(:tour1) { FactoryBot.create :tour, vehicle_type:'feet' }
      let!(:tour2) { FactoryBot.create :tour, vehicle_type:'feet' }
      let!(:tour3) { FactoryBot.create :tour, vehicle_type:'car' }
      let!(:tour4) { FactoryBot.create :tour, vehicle_type:'car' }
      let!(:tour5) { FactoryBot.create :tour, vehicle_type:'feet' }

      it "returns status 200" do
        get 'index', params: { token: user.token, vehicle_type:'car', :format => :json }
        expect(response.status).to eq 200
      end

      it "returns only matching vehicle type tours" do
        get 'index', params: { token: user.token, vehicle_type:'car', :format => :json }
        expect(assigns(:tours)).to match_array([tour4, tour3])
      end

    end

    context "with location parameter" do

      let!(:tour1) { FactoryBot.create :tour }
      let!(:tour_point1) { FactoryBot.create :tour_point, tour: tour1, latitude: 10, longitude: 12 }
      let!(:tour2) { FactoryBot.create :tour }
      let!(:tour_point2) { FactoryBot.create :tour_point, tour: tour2, latitude: 9.9, longitude: 10.1 }
      let!(:tour3) { FactoryBot.create :tour }
      let!(:tour_point3) { FactoryBot.create :tour_point, tour: tour3, latitude: 10, longitude: 10 }
      let!(:tour4) { FactoryBot.create :tour }
      let!(:tour_point4) { FactoryBot.create :tour_point, tour: tour4, latitude: 10.05, longitude: 9.95 }
      let!(:tour5) { FactoryBot.create :tour }
      let!(:tour_point5) { FactoryBot.create :tour_point, tour: tour5, latitude: 12, longitude: 10 }

      it "returns status 200" do
        get 'index', params: { token: user.token, latitude: 10.0, longitude: 10.0, :format => :json }
        expect(response.status).to eq 200
      end

      it "returns only matching location tours" do
        get 'index', params: { token: user.token, latitude: 10.0, longitude: 10.0, :format => :json }
        expect(assigns(:tours)).to match_array([tour4, tour3])
      end

      it "returns only matching location tours with provided distance" do
        get 'index', params: { token: user.token, latitude: 10.0, longitude: 10.0, distance: 20.0, :format => :json }
        expect(assigns(:tours)).to match_array([tour4, tour3, tour2])
      end

    end

    context "with status parameter" do
      let!(:ongoing_tour) { FactoryBot.create :tour, status: "ongoing" }
      let!(:closed_tour) { FactoryBot.create :tour, status: "closed" }

      context "ongoing" do
        before { get 'index', params: { token: user.token, status: "ongoing", format: :json } }
        it { expect(JSON.parse(response.body)["tours"].map{|t| t["id"]}).to eq([ongoing_tour.id]) }
      end

      context "closed" do
        before { get 'index', params: { token: user.token, status: "closed", format: :json } }
        it { expect(JSON.parse(response.body)["tours"].map{|t| t["id"]}).to eq([closed_tour.id]) }
      end
    end

    context "public user" do
      let(:public_user) { FactoryBot.create(:public_user) }
      before { get 'index', params: { token: public_user.token, status: "ongoing", format: :json } }
      it { expect(response.status).to eq(403) }
    end
  end

  describe "POST create" do
    let!(:user) { FactoryBot.create :pro_user }
    let!(:tour) { FactoryBot.build :tour }

    context "with correct type" do
      before { FactoryBot.create(:android_app) }
      before { post 'create', params: { token: user.token, tour: {tour_type: tour.tour_type,
                                                         status:tour.status,
                                                         vehicle_type:tour.vehicle_type,
                                                         distance: 123.456,
                                                         start_time: "2016-01-01T19:09:06.000+01:00"}, format: :json } }

      it { expect(response.status).to eq(201) }
      it { expect(Tour.last.tour_type).to eq(tour.tour_type) }
      it { expect(Tour.last.status).to eq(tour.status) }
      it { expect(Tour.last.vehicle_type).to eq(tour.vehicle_type) }
      it { expect(Tour.last.user).to eq(user) }
      it { expect(Tour.last.members).to eq([user]) }
      it { expect(Tour.last.created_at).to eq(DateTime.parse("2016-01-01T19:09:06.000+01:00")) }
      it { expect(JoinRequest.last.status).to eq("accepted") }

      it "responds with tour" do
        res = JSON.parse(response.body)
        last_tour = Tour.last
        expect(res).to eq({
          "tour" => {
            "id" => last_tour.id,
            "uuid" => last_tour.id.to_s,
            "tour_type" => "medical",
            "status" => "ongoing",
            "vehicle_type" => "feet",
            "distance" => 123,
            "organization_name" => last_tour.user.organization.name,
            "organization_description" => "Association description",
            "start_time" => last_tour.created_at.iso8601(3),
            "end_time" => last_tour.closed_at,
            "author" => {
              "id" => user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "partner" => nil
            },
            "number_of_people" => 1,
            "join_status" => "accepted",
            "tour_points" => [],
            "number_of_unread_messages" => 0,
            "updated_at" => last_tour.updated_at.iso8601(3)
          }
        })
      end
    end

    it "doesn't send join request accepted push" do
      FactoryBot.create(:android_app)
      expect_any_instance_of(IosNotificationService).to_not receive(:send_notification)
      expect_any_instance_of(AndroidNotificationService).to_not receive(:send_notification)
      post 'create', params: { token: user.token, tour: {tour_type: tour.tour_type, status:tour.status, vehicle_type:tour.vehicle_type, distance: 123.456}, format: :json }
    end

    context "with incorrect type" do
      before { post 'create', params: { token: user.token, tour: {tour_type: 'invalid', status:tour.status, vehicle_type:tour.vehicle_type, distance: 123.456}, :format => :json } }
      it { expect(response.status).to eq(400) }
    end

  end

  describe "GET show" do
    before { Timecop.freeze(Time.parse("10/10/2010").at_beginning_of_day) }
    let(:user) { FactoryBot.create :pro_user }

    context "with correct id" do
      let!(:tour) { FactoryBot.create :tour, :filled }
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(response.status).to eq(200) }

      it "responds with tour" do
        res = JSON.parse(response.body)
        last_tour = Tour.last
        expect(res).to eq({
          "tour" => {
            "id" => last_tour.id,
            "uuid" => last_tour.id.to_s,
            "tour_type" => "medical",
            "status" => "closed",
            "vehicle_type" => "feet",
            "distance" => tour.length,
            "organization_name" => last_tour.user.organization.name,
            "organization_description" => "Association description",
            "start_time" => last_tour.created_at.iso8601(3),
            "end_time" => last_tour.closed_at.iso8601(3),
            "author" => {
              "id" => last_tour.user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "partner" => nil
            },
            "number_of_people" =>  1,
            "join_status" => "not_requested",
            "tour_points" => [
              { "latitude" => 49.40752907, "longitude" => 0.26782405 },
              { "latitude" => 49.40774009, "longitude" => 0.26870057 }
            ],
            "number_of_unread_messages" => 0,
            "updated_at" => last_tour.updated_at.iso8601(3)
          }
        })
      end
    end

    context "with unexisting id" do
      let!(:user) { FactoryBot.create :pro_user }

      it "returns error 404" do
        expect {
          get 'show', params: { id: 0, token: user.token, format: :json }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "has simplified tour points" do
      let!(:tour) { FactoryBot.create(:tour)}
      let!(:tour_points) { FactoryBot.create_list(:tour_point, 2, tour: tour)}
      let!(:simplified_tour_points) { FactoryBot.create(:simplified_tour_point, tour: tour)}
      before { $redis.set("entourage:tours:#{tour.id}:tour_points", [{lat: 1.0, lng: 1.0}].to_json) }
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(JSON.parse(response.body)["tour"]["tour_points"].count).to eq(1) }
    end

    context "don't have simplified tour points" do
      let!(:tour) { FactoryBot.create(:tour, :filled)}
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(JSON.parse(response.body)["tour"]["tour_points"].count).to eq(2) }
    end

    context "has 2 unread messages" do
      let!(:tour) { FactoryBot.create :tour }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: "accepted", last_message_read: DateTime.parse("20/10/2015")) }
      let!(:new_chat_messages) { FactoryBot.create_list(:chat_message, 2, created_at: DateTime.parse("21/10/2015"), messageable: tour)}
      let!(:old_chat_message) { FactoryBot.create(:chat_message, created_at: DateTime.parse("19/10/2015"), messageable: tour)}
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(JSON.parse(response.body)["tour"]["number_of_unread_messages"]).to eq(2) }
    end

    context "has 0 unread messages" do
      let!(:tour) { FactoryBot.create :tour }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: "accepted", last_message_read: DateTime.parse("20/10/2015")) }
      let!(:old_chat_message) { FactoryBot.create(:chat_message, created_at: DateTime.parse("19/10/2015"), messageable: tour)}
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(JSON.parse(response.body)["tour"]["number_of_unread_messages"]).to eq(0) }
    end

    context "has never read a message" do
      let!(:tour) { FactoryBot.create :tour }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: "accepted", last_message_read: nil) }
      let!(:old_chat_message) { FactoryBot.create(:chat_message, created_at: DateTime.parse("19/10/2015"), messageable: tour)}
      before { get 'show', params: { id: tour.id, token: user.token, format: :json } }
      it { expect(JSON.parse(response.body)["tour"]["number_of_unread_messages"]).to eq(1) }
    end
  end

  describe "PUT update" do
    before { Timecop.freeze(DateTime.parse("10/10/2010").at_beginning_of_day) }
    let!(:user) { FactoryBot.create :pro_user }
    let!(:other_user) { FactoryBot.create :pro_user }
    let(:tour) { FactoryBot.create(:tour, :filled, user: user) }

    context "with correct id" do
      before { put 'update', params: { id: tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 123.456}, format: :json } }

      it { expect(response.status).to eq(200) }
      it { expect(tour.reload.status).to eq("closed") }
      it { expect(tour.reload.vehicle_type).to eq("car") }
      it { expect(tour.reload.tour_type).to eq("medical") }

      it "responds with tour" do
        res = JSON.parse(response.body)
        expect(res).to eq({
          "tour" => {
            "id" => tour.id,
            "uuid" => tour.id.to_s,
            "tour_type" => "medical",
            "status" => "closed",
            "vehicle_type" => "car",
            "distance" => tour.length,
            "organization_name" => tour.user.organization.name,
            "organization_description" => "Association description",
            "start_time" => tour.created_at.iso8601(3),
            "end_time" => tour.closed_at.iso8601(3),
            "author" => {
              "id" => tour.user.id,
              "display_name" => "John D.",
              "avatar_url" => nil,
              "partner" => nil
            },
            "number_of_people" =>  1,
            "join_status" => "not_requested",
            "tour_points" => [
              { "latitude" => 49.40752907, "longitude" => 0.26782405 },
              { "latitude" => 49.40774009, "longitude" => 0.26870057 }
            ],
            "number_of_unread_messages" => 0,
            "updated_at" => tour.updated_at.iso8601(3)
          }
        })
      end
    end

    context "close tour" do
      context "tour open" do
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :ongoing) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 633.0878, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(open_tour.reload.closed?).to be true }
        it { expect(ActionMailer::Base.deliveries.last).to be nil} # tour_report mail has been removed: we do not maintain tours anymore
        it { expect(open_tour.reload.length).to eq(633)}
      end

      context "tour closed" do
        let(:closed_tour) { FactoryBot.create(:tour, user: user, status: :closed) }
        before { put 'update', params: { id: closed_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 123.456, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(closed_tour.reload.closed?).to be true }
        it { expect(ActionMailer::Base.deliveries.last).to be nil}
      end

      context "sends end_time" do
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :ongoing) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 633.0878, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(open_tour.reload.closed_at).to eq(DateTime.parse("2016-01-01T20:09:06.000+01:00"))}
      end

      context "doesn't send end_time and has tour_points" do
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :ongoing) }
        let!(:last_point) { FactoryBot.create(:tour_point, tour: open_tour, passing_time: DateTime.parse("2016-01-01T20:09:06.000+01:00")) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 633.0878}, format: :json } }
        it { expect(open_tour.reload.closed_at).to eq(DateTime.parse("2016-01-01T20:09:06.000+01:00"))}
      end

      context "doesn't send end_time and no tour_points" do
        Timecop.freeze(DateTime.parse("10/10/2010"))
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :ongoing) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"closed", vehicle_type:"car", distance: 633.0878}, format: :json } }
        it { expect(open_tour.reload.closed_at).to eq(DateTime.parse("10/10/2010"))}
      end
    end

    context "freeze tour" do
      context "tour open" do
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :ongoing) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"freezed", vehicle_type:"car", distance: 633.0878, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(open_tour.reload.frozen?).to be false }
      end

      context "not the author tour of the tour" do
        let(:open_tour) { FactoryBot.create(:tour, status: :closed) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"freezed", vehicle_type:"car", distance: 633.0878, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(open_tour.reload.freezed?).to be false }
      end

      context "tour closed" do
        let(:open_tour) { FactoryBot.create(:tour, user: user, status: :closed) }
        before { put 'update', params: { id: open_tour.id, token: user.token, tour:{tour_type:"medical", status:"freezed", vehicle_type:"car", distance: 633.0878, end_time: "2016-01-01T20:09:06.000+01:00"}, format: :json } }
        it { expect(open_tour.reload.freezed?).to be true }
      end
    end

    context "with unexisting id" do
      it { expect {
            put 'update', params: { id: 0, token: user.token, tour:{tour_type:"medical", status:"ongoing", vehicle_type:"car", distance: 123.456}, format: :json }
          }.to raise_error(ActiveRecord::RecordNotFound)
        }
    end

    context "with incorrect_user" do
      before { put 'update', params: { id: tour.id, token: other_user.token, tour:{tour_type:"medical", status:"ongoing", vehicle_type:"car", distance: 123.456}, format: :json } }
      it { expect(response.status).to eq(403) }
    end
  end

  describe "PUT read" do
    let!(:user) { FactoryBot.create(:pro_user) }
    let!(:tour) { FactoryBot.create(:tour) }

    context "not signed in" do
      before { put :read, params: { id: tour.to_param } }
      it { expect(response.status).to eq(401) }
    end

    context "user is accepted in tour" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: JoinRequest::ACCEPTED_STATUS, last_message_read: old_date) }
      before { put :read, params: { id: tour.to_param, token: user.token } }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to be > old_date }
    end

    context "user is not accepted in tour" do
      let(:old_date) { DateTime.parse("15/10/2010") }
      let!(:join_request) { FactoryBot.create(:join_request, joinable: tour, user: user, status: JoinRequest::PENDING_STATUS, last_message_read: old_date) }
      before { put :read, params: { id: tour.to_param, token: user.token } }
      it { expect(response.status).to eq(204) }
      it { expect(join_request.reload.last_message_read).to eq(old_date) }
    end
  end
end
