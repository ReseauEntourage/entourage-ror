require 'rails_helper'
include AuthHelper

describe Admin::NeighborhoodMessageBroadcastsController do
  let!(:user) { admin_basic_login }

  around { |example| Sidekiq::Testing.disable!(&example) }

  describe 'POST #schedule' do
    let!(:neighborhood) { create(:neighborhood) }
    let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, conversation_ids: [neighborhood.id]) }

    context 'with a valid future date' do
      let(:request) {
        post :schedule, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { scheduled_date: 1.day.from_now.to_date.to_s, scheduled_time: '10:00' }
        }
      }

      it { expect { request }.to change { ScheduledPublication.count }.by(1) }

      it 'schedules the broadcast' do
        request

        expect(neighborhood_message_broadcast.reload.status).to eq('scheduled')
        expect(neighborhood_message_broadcast.scheduled_at).to be_present
      end

      it 'schedules the publish job' do
        request

        scheduled_publication = ScheduledPublication.last
        job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
        expect(job).to be_present
      end
    end

    context 'with a date in the past' do
      let(:request) {
        post :schedule, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { scheduled_date: 1.day.ago.to_date.to_s, scheduled_time: '10:00' }
        }
      }

      it { expect { request }.not_to change { neighborhood_message_broadcast.reload.status } }
      it { expect { request }.not_to change { ScheduledPublication.count } }
    end

    context 'when already sent' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :sent) }
      let(:request) {
        post :schedule, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { scheduled_date: 1.day.from_now.to_date.to_s, scheduled_time: '10:00' }
        }
      }

      it { expect { request }.not_to change { ScheduledPublication.count } }
    end
  end

  describe 'GET #index' do
    render_views

    context 'scheduled tab' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now) }
      let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

      before { get :index, params: { status: :scheduled } }

      it { expect(assigns(:neighborhood_message_broadcasts)).to eq([neighborhood_message_broadcast]) }
      it { expect(response.status).to eq(200) }
    end
  end

  describe 'GET #edit' do
    render_views

    let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now) }
    let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

    before { get :edit, params: { id: neighborhood_message_broadcast.id } }

    it { expect(assigns(:scheduled_publication)).to eq(scheduled_publication) }
    it { expect(response.status).to eq(200) }
  end

  describe 'GET #new' do
    render_views

    before { get :new }

    it { expect(response.status).to eq(200) }
  end
end
