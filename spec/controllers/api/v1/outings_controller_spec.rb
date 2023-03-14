require 'rails_helper'

describe Api::V1::OutingsController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood_1) { create :neighborhood }
  let(:neighborhood_2) { create :neighborhood }
  let(:entourage_image) { FactoryBot.create(:entourage_image) }

  subject { JSON.parse(response.body) }

  describe 'GET index' do
    let(:request) { get :index, params: { token: user.token } }

    let(:latitude) { 48.85 }
    let(:longitude) { 2.27 }

    let(:outing) { FactoryBot.create(:outing, latitude: latitude, longitude: longitude) }
    let!(:join_request) { create(:join_request, user: outing.user, joinable: outing, status: :accepted, role: :organizer) }

    describe 'do not get closed' do
      let!(:closed) { create :outing, status: :closed, latitude: latitude, longitude: longitude }

      before { get :index, params: { token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key('outings') }
      it { expect(subject['outings'].count).to eq(1) }
      it { expect(subject['outings'][0]['id']).to eq(outing.id) }
    end

    describe 'period' do
      let!(:outing) { create :outing, latitude: latitude, longitude: longitude, metadata: { starts_at: starts_at } }

      before { get :index, params: { token: user.token, period: period } }

      context 'default' do
        let(:period) { nil }

        context 'display future' do
          let(:starts_at) { 1.hour.from_now }

          it { expect(subject['outings'].count).to eq(1) }
          it { expect(subject['outings'][0]['id']).to eq(outing.id) }
        end

        context 'display recently past' do
          let(:starts_at) { 1.hour.ago }

          it { expect(subject['outings'].count).to eq(1) }
          it { expect(subject['outings'][0]['id']).to eq(outing.id) }
        end

        context 'do not display ancient past' do
          let(:starts_at) { 1.year.ago }

          it { expect(subject['outings'].count).to eq(0) }
        end
      end
    end

    context "some user is a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("outings") }
      it { expect(subject["outings"].count).to eq(1) }
      it { expect(subject["outings"][0]).to have_key("members") }
      it { expect(subject["outings"][0]["members"]).to eq([{
        "id" => outing.user_id,
        "display_name" => "John D.",
        "avatar_url" => nil
      }]) }
    end

    context "some users are members" do
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: outing, status: :accepted, role: :organizer) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: outing, status: :accepted, role: :organizer) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key("outings") }
      it { expect(subject["outings"].count).to eq(1) }
      it { expect(subject["outings"][0]).to have_key("members") }
      it { expect(subject["outings"][0]["members"].count).to eq(3) }
    end

    context "user being a member" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted, role: :organizer) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(0) }
    end

    context "user being a member along with some users" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :accepted, role: :organizer) }
      let!(:join_request_1) { create(:join_request, user: FactoryBot.create(:public_user), joinable: outing, status: :accepted, role: :organizer) }
      let!(:join_request_2) { create(:join_request, user: FactoryBot.create(:public_user), joinable: outing, status: :accepted, role: :organizer) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(0) }
    end

    context "user being a member but not accepted" do
      let!(:join_request) { create(:join_request, user: user, joinable: outing, status: :pending, role: :organizer) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(1) }
    end

    context "user not being a member" do
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(1) }
    end

    context "params coordinates matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 48.84, longitude: 2.28, travel_distance: 10 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(1) }
    end

    context "params coordinates do not matches" do
      let(:request) { get :index, params: { token: user.token, latitude: 47, longitude: 2, travel_distance: 1 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(0) }
    end

    context "user coordinates matches" do
      before { user.stub(:latitude) { 48.84 }}
      before { user.stub(:longitude) { 2.28 }}

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(1) }
    end

    context "user coordinates do not matches" do
      before { User.any_instance.stub(:latitude) { 40 } }
      before { User.any_instance.stub(:longitude) { 2 } }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(0) }
    end

    context "ordered by starts_at desc" do
      let(:outing) { FactoryBot.create(:outing, metadata: { starts_at: 1.day.from_now }) }
      let(:outing_1) { FactoryBot.create(:outing, metadata: { starts_at: 1.hour.from_now }) }
      let!(:join_request_1) { create(:join_request, user: outing_1.user, joinable: outing_1, status: :accepted, role: :organizer) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject["outings"].count).to eq(2) }
      it { expect(subject["outings"][0]["id"]).to eq(outing_1.id) }
      it { expect(subject["outings"][1]["id"]).to eq(outing.id) }
    end
  end

  describe 'POST create' do
    let(:params) { {
      title: "Apéro Entourage",
      # description: "Apéro Entourage",
      # event_url: 'bar',
      latitude: 48.868959,
      longitude: 2.390185,
      neighborhood_ids: [neighborhood_1.id, neighborhood_2.id],
      interests: ['animaux', 'other'],
      other_interest: 'poterie',
      entourage_image_id: entourage_image.id,
      metadata: {
        starts_at: 1.minute.from_now,
        ends_at: 1.minute.from_now + 1.minute,
        place_name: "Le Dorothy",
        street_address: "85 bis rue de Ménilmontant, 75020 Paris, France",
        google_place_id: "ChIJFzXXy-xt5kcRg5tztdINnp0",
        place_limit: 5
      }
    } }

    context "not signed in" do
      before { post :create, params: { outing: params } }
      it { expect(response.status).to eq(401) }
      it { expect(Outing.count).to eq(0) }
    end

    context "not joined" do
      before { post :create, params: { outing: params, token: user.token } }
      it { expect(response.body).to include("User has to be a member of every neighborhoods") }
      it { expect(response.status).to eq(400) }
      it { expect(Outing.count).to eq(0) }
    end

    context "signed in" do
      let!(:join_request_1) { FactoryBot.create(:join_request, joinable: neighborhood_1, user: user, status: :accepted) }
      let!(:join_request_2) { FactoryBot.create(:join_request, joinable: neighborhood_2, user: user, status: :accepted) }

      context "without all required parameters" do
        before { post :create, params: { outing: {
          title: "foobar",
          longitude: 1.123,
          latitude: 4.567
        }, token: user.token } }

        it { expect(response.status).to eq(400) }
        it { expect(Outing.count).to eq(0) }
        it { expect(neighborhood_1.outings.count).to eq(0) }
        it { expect(neighborhood_2.outings.count).to eq(0) }
        it { expect(JSON.parse(response.body)).to have_key("message") }
        it { expect(JSON.parse(response.body)).to have_key("reasons") }
      end

      context "with all required parameters" do
        before { post :create, params: { outing: params, token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Outing.count).to eq(1) }
        it { expect(neighborhood_1.outings.count).to eq(1) }
        it { expect(neighborhood_2.outings.count).to eq(1) }
        it { expect(Outing.last.interest_list).to match_array(["animaux", "other"]) }
        it { expect(Outing.last.other_interest).to eq("poterie") }
        it { expect(Outing.last.metadata[:place_limit].to_i).to eq(5) }
        it { expect(Outing.last.metadata[:landscape_url]).to eq("path/to/landscape") }
      end

      context "interests are optional" do
        before { post :create, params: { outing: params.except(:interests, :other_interest), token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(Outing.count).to eq(1) }
        it { expect(Outing.last.interest_list).to match_array([]) }
        it { expect(Outing.last.other_interest).to be_nil }
      end

      context "place_limit is nullable" do
        before {
          params[:metadata][:place_limit] = nil
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(201) }
        it { expect(Outing.count).to eq(1) }
        it { expect(Outing.last.metadata[:place_limit]).to be_blank }
      end

      context "place_limit is optional" do
        before {
          params[:metadata] = params[:metadata].except(:place_limit)
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(201) }
        it { expect(Outing.count).to eq(1) }
        it { expect(Outing.last.metadata[:place_limit]).to be_blank }
      end

      context "starts_at in the future" do
        before {
          params[:metadata][:starts_at] = 1.day.from_now
          params[:metadata][:ends_at] = 1.day.from_now + 1.hour
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("outing") }
      end

      context "starts_at in the past" do
        before {
          params[:metadata][:starts_at] = 1.day.ago
          params[:metadata][:ends_at] = 1.day.ago + 1.hour
          post :create, params: { outing: params, token: user.token }
        }

        it { expect(response.status).to eq(400) }
        it { expect(subject).to have_key("message") }
      end

      context "with recurrency" do
        before { post :create, params: { outing: params.merge({ recurrency: 7 }), token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("outing") }
        it { expect(Outing.count).to eq(5) }
        it { expect(OutingRecurrence.count).to eq(1) }
        it { expect(Outing.last.recurrence).not_to be_nil }
      end

      context "without recurrency" do
        before { post :create, params: { outing: params.merge({ recurrency: nil }), token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("outing") }
        it { expect(Outing.count).to eq(1) }
        it { expect(OutingRecurrence.count).to eq(0) }
        it { expect(Outing.last.recurrence).to be_nil }
      end
    end
  end

  describe 'PUT update' do
    let(:outing) { FactoryBot.create(:outing, status: :open) }

    context "not signed in" do
      before { patch :update, params: { id: outing.to_param, outing: { title: "new title" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      let(:params) { {} }
      let(:request) { patch :update, params: { id: outing.to_param, outing: params, token: user.token } }

      context "user is not creator" do
        let(:params) { { title: "new title" } }

        before { request }

        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:outing) { FactoryBot.create(:outing, :outing_class, user: user, status: :open, interests: ['animaux', 'other']) }
        let(:params) { { title: "New title", metadata: { place_limit: 100 } } }

        before { request }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outing') }
        it { expect(subject['outing']['title']).to eq('New title') }
        it { expect(subject['outing']['metadata']['place_limit']).to eq('100') }
        it { expect(subject['outing']['interests']).to eq(["animaux", "other"]) }
      end

      context "close" do
        let(:outing) { FactoryBot.create(:outing, :joined, user: user, status: :open) }

        before { patch :update, params: { id: outing.to_param, outing: { status: :closed }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outing') }
        it { expect(subject['outing']['status']).to eq('closed') }
        it { expect(outing.reload.status).to eq('closed') }
      end

      context "remove relationship with neighborhood" do
        let(:outing) { FactoryBot.create(:outing, :with_neighborhood, status: :open, user: creator) }
      end

      context "cancel sends notification" do
        let(:outing) { FactoryBot.create(:outing, :joined, user: user, status: :open) }

        let(:participant) { create :public_user, first_name: "Jane" }
        let!(:join_request) { create :join_request, user: participant, joinable: outing, status: :accepted }

        before {
          allow_any_instance_of(PushNotificationTrigger).to receive(:notify)
          expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
            sender_id: outing.user_id,
            referent: outing.becomes(Outing),
            instance: outing.becomes(Outing),
            users: [participant],
            params: {
              object: "Foobar",
              content: "Cet événement prévu le #{I18n.l(outing.starts_at.to_date)} vient d'être annulé",
            }
          )
        }
        before { patch :update, params: { id: outing.to_param, outing: { status: :cancelled }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outing') }
        it { expect(subject['outing']['status']).to eq('cancelled') }
        it { expect(outing.reload.status).to eq('cancelled') }
      end

      context "cancel recurrency" do
        let(:outing) { FactoryBot.create(:outing, :with_recurrence, user: user, status: :open) }
        let(:subject) { OutingRecurrence.unscoped.find_by_identifier(outing.recurrency_identifier)}

        before { patch :update, params: { id: outing.to_param, outing: { recurrency: 0 }, token: user.token } }

        it { expect(subject.continue).to eq(false) }
        it { expect(response.status).to eq(200) }
      end

      context "cancel recurrency is not valid if recurrency > 0" do
        let(:outing) { FactoryBot.create(:outing, :with_recurrence, user: user, status: :open) }
        let(:subject) { OutingRecurrence.unscoped.find_by_identifier(outing.recurrency_identifier)}

        before { patch :update, params: { id: outing.to_param, outing: { recurrency: 15 }, token: user.token } }

        it { expect(subject.continue).to eq(true) }
      end

      context "cancel recurrency is not valid if recurrency is nil" do
        let(:outing) { FactoryBot.create(:outing, :with_recurrence, user: user, status: :open) }
        let(:subject) { OutingRecurrence.unscoped.find_by_identifier(outing.recurrency_identifier)}

        before { patch :update, params: { id: outing.to_param, outing: { recurrency: nil }, token: user.token } }

        it { expect(subject.continue).to eq(true) }
      end

      context "change recurrence" do
        let(:start_at) { 1.hour.from_now }
        let(:end_at) { 2.hours.from_now }

        let(:recurrence) { FactoryBot.create(:outing_recurrence, recurrency: 7) }

        let(:outing) { FactoryBot.create(:outing, :outing_class, user: user, recurrence: recurrence, metadata: {
          starts_at: start_at,
          ends_at: end_at
        }) }
        let!(:sibling_1) { FactoryBot.create(:outing, :outing_class, user: user, recurrence: recurrence, metadata: {
          starts_at: start_at + 7.days,
          ends_at: end_at + 7.days
        }) }
        let!(:sibling_2) { FactoryBot.create(:outing, :outing_class, user: user, recurrence: recurrence, metadata: {
          starts_at: start_at + 14.days,
          ends_at: end_at + 14.days
        }) }
        let!(:sibling_3) { FactoryBot.create(:outing, :outing_class, user: user, recurrence: recurrence, metadata: {
          starts_at: start_at + 21.days,
          ends_at: end_at + 21.days
        }) }
        let!(:sibling_4) { FactoryBot.create(:outing, :outing_class, user: user, recurrence: recurrence, metadata: {
          starts_at: start_at + 28.days,
          ends_at: end_at + 28.days
        }) }
        let!(:stranger) { FactoryBot.create(:outing, :outing_class, user: user, metadata: {
          starts_at: start_at,
          ends_at: end_at
        }) }

        let(:subject) { OutingRecurrence.unscoped.find_by_identifier(outing.recurrency_identifier)}

        context "from 7 to 14" do
          before { patch :update, params: { id: outing.to_param, outing: { recurrency: 14 }, token: user.token } }

          it { expect(subject.continue).to eq(true) }
          it { expect(response.status).to eq(200) }

          it {
            expect(outing.reload.status).to eq("open")
            expect(sibling_1.reload.status).to eq("cancelled")
            expect(sibling_2.reload.status).to eq("open")
            expect(sibling_3.reload.status).to eq("cancelled")
            expect(sibling_4.reload.status).to eq("open")
          }
        end

        context "from 14 to 7" do
          let(:recurrence) { FactoryBot.create(:outing_recurrence, recurrency: 14) }

          before { patch :update, params: { id: outing.to_param, outing: { recurrency: 7 }, token: user.token } }

          it { expect(subject.continue).to eq(true) }
          it { expect(response.status).to eq(200) }

          it {
            expect(outing.reload.status).to eq("open")
            expect(sibling_1.reload.status).to eq("open")
            expect(sibling_2.reload.status).to eq("open")
            expect(sibling_3.reload.status).to eq("open")
            expect(sibling_4.reload.status).to eq("open")
          }

          let(:start_dates) { (start_at.to_datetime..(start_at + 64.days).to_datetime).step(7).to_a }
          let(:end_dates) { (end_at.to_datetime..(end_at + 64.days).to_datetime).step(7).to_a }

          it { expect(outing.siblings.count).to eq(10) }
          it { expect(outing.siblings.pluck("metadata->>'starts_at'").map(&:to_datetime)).to match_array(start_dates) }
          it { expect(outing.siblings.pluck("metadata->>'ends_at'").map(&:to_datetime)).to match_array(end_dates) }
        end

      end

      context "change recurrence from nil to 7" do
        let(:start_at) { 1.hour.from_now }
        let(:end_at) { 2.hours.from_now }

        let(:outing) { FactoryBot.create(:outing, :outing_class, user: user, metadata: {
          starts_at: start_at,
          ends_at: end_at
        }) }

        before { patch :update, params: { id: outing.to_param, outing: { recurrency: 7 }, token: user.token } }

        it { expect(outing.reload.recurrence.continue).to eq(true) }
        it { expect(outing.reload.siblings.count).to eq(5) }
      end
    end
  end

  describe 'PUT batch_update' do
    let(:creator) { FactoryBot.create(:public_user) }

    let(:start_at) { 1.hour.from_now }
    let(:end_at) { 2.hours.from_now }

    let(:recurrence) { FactoryBot.create(:outing_recurrence) }
    let!(:outing) { FactoryBot.create(:outing, :outing_class, user: creator, recurrence: recurrence, metadata: {
      starts_at: start_at,
      ends_at: end_at
    }) }
    let!(:sibling) { FactoryBot.create(:outing, :outing_class, user: creator, recurrence: recurrence, metadata: {
      starts_at: start_at + 7.days,
      ends_at: end_at + 7.days
    }) }
    let!(:stranger) { FactoryBot.create(:outing, :outing_class, user: creator, metadata: {
      starts_at: start_at,
      ends_at: end_at
    }) }

    context "not signed in" do
      before { patch :batch_update, params: { id: outing.to_param, outing: { title: "new title" } } }
      it { expect(response.status).to eq(401) }
    end

    context "signed in" do
      context "user is not creator" do
        before { patch :batch_update, params: { id: outing.to_param, outing: { title: "new title" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:creator) { user }

        before { patch :batch_update, params: { id: outing.to_param, outing: { title: "New title", metadata: { place_limit: 100 } }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outings') }

        it {
          [outing, sibling].each do |event|
            expect(outing.reload.title).to eq('New title')
            expect(outing.reload.metadata[:place_limit]).to eq("100")
          end
        }

        it { expect(stranger.reload.title).to eq('Foobar') }
        it { expect(stranger.reload.metadata[:place_limit]).to eq(nil) }
      end

      context "change starts_at or ends_at" do
        let(:creator) { user }

        before { patch :batch_update, params: { id: outing.to_param, outing: { title: "New title", metadata: {
          starts_at: start_at + 3.hours,
          ends_at: end_at + 1.day
        } }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outings') }

        it { expect(outing.reload.metadata[:starts_at]).to be_within(1.second).of (start_at + 3.hours) }
        it { expect(outing.reload.metadata[:ends_at]).to be_within(1.second).of (end_at + 1.day) }

        it { expect(sibling.reload.metadata[:starts_at]).to be_within(1.second).of (start_at + 7.days + 3.hours) }
        it { expect(sibling.reload.metadata[:ends_at]).to be_within(1.second).of (end_at + 8.days) }

        it { expect(stranger.reload.metadata[:starts_at]).to be_within(1.second).of start_at }
        it { expect(stranger.reload.metadata[:ends_at]).to be_within(1.second).of end_at }
      end
    end
  end

  describe 'GET show' do
    let(:outing) { FactoryBot.create(:outing, status: "open") }

    context 'no deeplink' do
      before { get :show, params: { token: user.token, id: identifier } }

      context 'from id' do
        let(:identifier) { outing.id }

        it { expect(response.status).to eq 200 }
        it { expect(subject).to have_key("outing") }
        it { expect(subject["outing"]).to have_key("posts") }
      end

      context 'from uuid_v2' do
        let(:identifier) { outing.uuid_v2 }

        it { expect(response.status).to eq 200 }
        it { expect(subject).to have_key("outing") }
        it { expect(subject["outing"]).to have_key("posts") }
      end
    end

    describe 'no deeplink' do
      before { get :show, params: { token: user.token, id: outing.id } }

      it { expect(response.status).to eq 200 }
      it { expect(subject).to have_key("outing") }
      it { expect(subject["outing"]).to have_key("posts") }
    end

    describe 'deeplink' do
      context 'using uuid_v2' do
        before { get :show, params: { token: user.token, id: outing.uuid_v2, deeplink: true } }

        it { expect(response.status).to eq 200 }
        it { expect(subject).to have_key('outing') }
        it { expect(subject['outing']['id']).to eq(outing.id) }
      end

      context 'using id fails' do
        before { get :show, params: { token: user.token, id: outing.id, deeplink: true } }

        it { expect(response.status).to eq 400 }
      end
    end
  end

  context 'cancel' do
    let(:creator) { create :pro_user }
    let(:outing) { create :outing, user: creator }
    let!(:join_request) { create(:join_request, user: outing.user, joinable: outing, status: :accepted, role: :organizer) }

    let(:result) { Outing.unscoped.find(outing.id) }

    describe 'not authorized' do
      before { post :cancel, params: { id: outing.id, cancellation_message: "foo" } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'not authorized cause should be creator' do
      before { expect_any_instance_of(PushNotificationTrigger).not_to receive(:notify) }
      before { post :cancel, params: { id: outing.id, outing: { cancellation_message: "foo" }, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'authorized' do
      let(:creator) { user }

      let(:participant) { create :public_user, first_name: "Jane" }
      let!(:join_request_2) { create :join_request, user: participant, joinable: outing, status: :accepted }

      before {
        allow_any_instance_of(PushNotificationTrigger).to receive(:notify)
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
          sender_id: outing.user_id,
          referent: outing.reload.becomes(Outing),
          instance: outing.reload.becomes(Outing),
          users: [participant],
          params: {
            object: "Foobar",
            content: "Cet événement prévu le #{I18n.l(outing.starts_at.to_date)} vient d'être annulé",
          }
        ).once
      }

      before { post :cancel, params: { id: outing.id, outing: { cancellation_message: "foo" }, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.status).to eq 'cancelled' }
    end

    describe 'authorized without cancellation_message' do
      let(:creator) { user }

      let(:participant) { create :public_user, first_name: "Jane" }
      let!(:join_request_2) { create :join_request, user: participant, joinable: outing, status: :accepted }

      before {
        allow_any_instance_of(PushNotificationTrigger).to receive(:notify)
        expect_any_instance_of(PushNotificationTrigger).to receive(:notify).with(
          sender_id: outing.user_id,
          referent: outing.reload.becomes(Outing),
          instance: outing.reload.becomes(Outing),
          users: [participant],
          params: {
            object: "Foobar",
            content: "Cet événement prévu le #{I18n.l(outing.starts_at.to_date)} vient d'être annulé",
          }
        ).once
      }

      before { post :cancel, params: { id: outing.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.status).to eq 'cancelled' }
    end
  end

  context 'destroy' do
    let(:creator) { create :pro_user }
    let(:outing) { create :outing, user: creator }
    let!(:join_request) { create(:join_request, user: outing.user, joinable: outing, status: :accepted, role: :organizer) }

    let(:result) { Outing.unscoped.find(outing.id) }

    describe 'not authorized' do
      before { delete :destroy, params: { id: outing.id } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'not authorized cause should be creator' do
      before { delete :destroy, params: { id: outing.id, token: user.token } }

      it { expect(response.status).to eq 401 }
      it { expect(result.status).to eq 'open' }
    end

    describe 'authorized' do
      let(:creator) { user }

      before { delete :destroy, params: { id: outing.id, token: user.token } }

      it { expect(response.status).to eq 200 }
      it { expect(result.status).to eq 'closed' }
    end
  end

  describe 'POST duplicate' do
    let(:creator) { user }
    let(:recurrence) { FactoryBot.create(:outing_recurrence) }
    let!(:outing) { FactoryBot.create(:outing, :with_neighborhood, status: :open, user: creator, recurrence: recurrence, recurrency_identifier: recurrence&.identifier, interests: [:sport]) }

    let(:request) { post :duplicate, params: { token: user.token, id: outing.id } }

    context 'not as creator' do
      let(:creator) { FactoryBot.create(:public_user) }
      it { expect(lambda { request }).to change { Outing.count }.by(0) }
      it { request ; expect(response.status).to eq(401) }
    end

    context 'without recurrence' do
      let(:recurrence) { nil }
      it { expect(lambda { request }).to change { Outing.count }.by(0) }
      it { request ; expect(response.status).to eq(401) }
    end

    context 'without unactive recurrence' do
      let(:recurrence) { FactoryBot.create(:outing_recurrence, continue: false) }
      it { expect(lambda { request }).to change { Outing.count }.by(0) }
      it { request ; expect(response.status).to eq(401) }
    end

    context 'duplication as creator' do
      it { expect(lambda { request }).to change { Outing.count }.by(1) }
    end

    context 'as creator' do
      let(:result) { subject['outing'] }
      let(:result_db) { Outing.find(subject['outing']['id']) }

      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key('outing') }
      it { expect(result).to have_key('metadata') }
      it { expect(result['metadata']['starts_at']).to eq((outing[:metadata][:starts_at] + 7.days).iso8601(3)) }

      it { expect(result['id']).to eq(Outing.last.id) }
      it { expect(result['id']).not_to eq(outing.id) }
      it { expect(result_db.member_ids).to match_array([user.id]) }
      it { expect(result_db.neighborhoods_entourages.count).to eq 1 }
      it { expect(result_db.neighborhoods.count).to eq 1 }
      it { expect(result['interests']).to match_array(['sport']) }
    end
  end

  describe 'POST #report' do
    let(:outing) { create :outing }

    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    before { stub_request(:post, "https://url.to.slack.com").to_return(status: 200) }

    context "valid params" do
      before {
        expect_any_instance_of(SlackServices::SignalOuting).to receive(:notify)
        post 'report', params: { token: user.token, id: outing.id, report: { signals: ['foo'], message: 'bar' } }
      }
      it { expect(response.status).to eq 201 }
    end

    context "missing signals" do
      before {
        expect_any_instance_of(SlackServices::SignalOuting).not_to receive(:notify)
        post 'report', params: { token: user.token, id: outing.id, report: { signals: [], message: 'bar' } }
      }
      it { expect(response.status).to eq 400 }
    end
  end
end
