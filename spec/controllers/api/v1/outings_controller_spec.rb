require 'rails_helper'

describe Api::V1::OutingsController do
  let(:user) { FactoryBot.create(:public_user) }
  let(:neighborhood_1) { create :neighborhood }
  let(:neighborhood_2) { create :neighborhood }
  let(:entourage_image) { FactoryBot.create(:entourage_image) }

  subject { JSON.parse(response.body) }

  describe 'GET index' do
    let!(:outing) { FactoryBot.create(:outing, status: "open") }
    let!(:neighborhood_outing) { FactoryBot.create(:outing, :joined, user: user, status: "open", neighborhoods: [neighborhood_1]) }

    before { get :index, params: { token: user.token } }

    it { expect(response.status).to eq(200) }
    it { expect(subject).to have_key("outings") }
    it { expect(subject["outings"].count).to eq(2) }
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
        starts_at: "2018-09-04T19:30:00+02:00",
        ends_at: "2018-09-04T20:30:00+02:00",
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

      context "with recurrency" do
        before { post :create, params: { outing: params.merge({ recurrency: 7 }), token: user.token } }

        it { expect(response.status).to eq(201) }
        it { expect(subject).to have_key("outing") }
        it { expect(Outing.count).to eq(1) }
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
      context "user is not creator" do
        before { patch :update, params: { id: outing.to_param, outing: { title: "new title" }, token: user.token } }
        it { expect(response.status).to eq(401) }
      end

      context "user is creator" do
        let(:outing) { FactoryBot.create(:outing, :joined, user: user, status: :open) }

        before { patch :update, params: { id: outing.to_param, outing: { title: "New title", metadata: { place_limit: 100 } }, token: user.token } }

        it { expect(response.status).to eq(200) }
        it { expect(subject).to have_key('outing') }
        it { expect(subject['outing']['title']).to eq('New title') }
        it { expect(subject['outing']['metadata']['place_limit']).to eq('100') }
      end

      context "cancel recurrency" do
        let(:outing) { FactoryBot.create(:outing, :with_recurrence, user: user, status: :open) }
        let(:subject) { OutingRecurrence.unscoped.find_by_identifier(outing.recurrency_identifier)}

        before { patch :update, params: { id: outing.to_param, outing: { recurrency: 0 }, token: user.token } }

        it { expect(subject.continue).to eq(false) }
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

    before { get :show, params: { token: user.token, id: outing.id } }

    it { expect(response.status).to eq 200 }
    it { expect(subject).to have_key("outing") }
  end

  describe 'POST duplicate' do
    let(:creator) { user }
    let(:recurrence) { FactoryBot.create(:outing_recurrence) }
    let!(:outing) { FactoryBot.create(:outing, :outing_class, status: :open, user: creator, recurrence: recurrence) }

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
      before { request }

      it { expect(response.status).to eq(200) }
      it { expect(subject).to have_key('outing') }
      it { expect(subject['outing']).to have_key('metadata') }
      it { expect(subject['outing']['metadata']['starts_at']).to eq((outing[:metadata][:starts_at] + 7.days).iso8601(3)) }

      it { expect(subject['outing']['id']).to eq(Outing.last.id) }
      it { expect(Outing.find(subject['outing']['id']).member_ids).to match_array([user.id]) }
    end
  end
end
