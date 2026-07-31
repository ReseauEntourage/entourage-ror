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
          neighborhood_message_broadcast: { scheduled_date: 1.day.from_now.to_date.strftime('%d/%m/%Y'), scheduled_hour: '10', scheduled_minute: '00' }
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
          neighborhood_message_broadcast: { scheduled_date: 1.day.ago.to_date.strftime('%d/%m/%Y'), scheduled_hour: '10', scheduled_minute: '00' }
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
          neighborhood_message_broadcast: { scheduled_date: 1.day.from_now.to_date.strftime('%d/%m/%Y'), scheduled_hour: '10', scheduled_minute: '00' }
        }
      }

      it { expect { request }.not_to change { ScheduledPublication.count } }
    end
  end

  describe 'GET #index' do
    render_views

    context 'scheduled tab' do
      let!(:neighborhood) { create(:neighborhood, participants: create_list(:public_user, 2)) }
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now, conversation_ids: [neighborhood.id]) }
      let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

      before { get :index, params: { status: :scheduled } }

      it { expect(assigns(:neighborhood_message_broadcasts)).to eq([neighborhood_message_broadcast]) }
      it { expect(response.status).to eq(200) }

      it 'shows the recipient count and a relative countdown, not just the group count' do
        recipients_count = neighborhood_message_broadcast.recipients.sum(:number_of_people)
        suffix = recipients_count == 1 ? '' : 's'

        expect(response.body).to include("#{recipients_count} destinataire#{suffix}")
        expect(response.body).to include('dans 1 jour')
      end
    end

    context 'scheduled tab with a failed broadcast' do
      # @caution a failed broadcast must stay visible here with a way to retry it
      # (EN-9403: "Tu peux réessayer depuis le back-office")
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.ago) }
      let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, status: :failed, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

      before { get :index, params: { status: :scheduled } }

      it { expect(assigns(:neighborhood_message_broadcasts)).to eq([neighborhood_message_broadcast]) }
      it { expect(response.body).to include('Réessayer maintenant') }
      it { expect(response.body).to include('en retard de') }
    end
  end

  describe 'GET #edit' do
    render_views

    let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now) }
    let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

    before { get :edit, params: { id: neighborhood_message_broadcast.id } }

    it { expect(assigns(:scheduled_publication)).to eq(scheduled_publication) }
    it { expect(response.status).to eq(200) }

    it 'renders a save button so title/content edits can actually be submitted' do
      expect(response.body).to include('Enregistrer')
    end
  end

  describe 'GET #edit for a failed broadcast' do
    render_views

    # @caution a failed broadcast must stay visible here with a way to retry it
    # (EN-9403: "Tu peux réessayer depuis le back-office")
    let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.ago) }
    let!(:scheduled_publication) { create(:scheduled_publication, publishable: neighborhood_message_broadcast, author: user, status: :failed, scheduled_at: neighborhood_message_broadcast.scheduled_at) }

    before { get :edit, params: { id: neighborhood_message_broadcast.id } }

    it { expect(assigns(:scheduled_publication)).to eq(scheduled_publication) }
    it { expect(response.body).to include('Réessayer maintenant') }
  end

  describe 'PATCH #update' do
    context 'draft broadcast' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft, title: 'old title') }

      it 'updates the title and content' do
        patch :update, params: { id: neighborhood_message_broadcast.id, neighborhood_message_broadcast: { title: 'new title', content: 'new content' } }

        expect(neighborhood_message_broadcast.reload.title).to eq('new title')
        expect(neighborhood_message_broadcast.content).to eq('new content')
      end
    end

    context 'scheduled broadcast (not yet sent)' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :scheduled, scheduled_at: 1.day.from_now, title: 'old title') }

      it 'updates the title and content without losing the schedule' do
        patch :update, params: { id: neighborhood_message_broadcast.id, neighborhood_message_broadcast: { title: 'new title', content: 'new content' } }

        neighborhood_message_broadcast.reload
        expect(neighborhood_message_broadcast.title).to eq('new title')
        expect(neighborhood_message_broadcast.content).to eq('new content')
        expect(neighborhood_message_broadcast.status).to eq('scheduled')
        expect(neighborhood_message_broadcast.scheduled_at).to be_present
      end
    end

    context 'with neighborhood_ids (tab "Par groupes")' do
      let!(:neighborhood) { create(:neighborhood) }
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft) }

      it 'saves the selected groups alongside the general fields, from a single submit' do
        patch :update, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { title: 'new title', neighborhood_ids: [neighborhood.id] }
        }

        neighborhood_message_broadcast.reload
        expect(neighborhood_message_broadcast.title).to eq('new title')
        expect(neighborhood_message_broadcast.neighborhood_ids).to eq([neighborhood.id])
      end
    end

    context 'with departements and area_type (tab "Par départements")' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft) }

      it 'saves the department filters alongside the general fields, from a single submit' do
        patch :update, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { title: 'new title', area_type: 'ville', departements: ['75'] }
        }

        neighborhood_message_broadcast.reload
        expect(neighborhood_message_broadcast.title).to eq('new title')
        expect(neighborhood_message_broadcast.area_type).to eq('ville')
        expect(neighborhood_message_broadcast.departements).to eq(['75'])
      end
    end

    context 'with the broadcast button (Envoyer)' do
      let!(:neighborhood) { create(:neighborhood) }
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft, conversation_ids: [neighborhood.id]) }

      let(:request) {
        patch :update, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: { title: 'new title', content: 'new content' },
          broadcast: '1'
        }
      }

      it 'saves the pending edits and immediately triggers the broadcast job with the up-to-date content' do
        expect(ConversationMessageBroadcastJob).to receive(:perform_later).with(neighborhood_message_broadcast.id, user.id, 'new content')

        request

        neighborhood_message_broadcast.reload
        expect(neighborhood_message_broadcast.title).to eq('new title')
        expect(neighborhood_message_broadcast.status).to eq('sent')
      end
    end

    context 'with the schedule button (Programmer)' do
      let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft, title: 'old title') }

      let(:request) {
        patch :update, params: {
          id: neighborhood_message_broadcast.id,
          neighborhood_message_broadcast: {
            title: 'new title',
            scheduled_date: 1.day.from_now.to_date.strftime('%d/%m/%Y'), scheduled_hour: '10', scheduled_minute: '00'
          },
          schedule: '1'
        }
      }

      it 'saves the pending edits and schedules the broadcast' do
        expect { request }.to change { ScheduledPublication.count }.by(1)

        neighborhood_message_broadcast.reload
        expect(neighborhood_message_broadcast.title).to eq('new title')
        expect(neighborhood_message_broadcast.status).to eq('scheduled')
      end

      context 'with a date in the past' do
        let(:request) {
          patch :update, params: {
            id: neighborhood_message_broadcast.id,
            neighborhood_message_broadcast: {
              title: 'new title',
              scheduled_date: 1.day.ago.to_date.strftime('%d/%m/%Y'), scheduled_hour: '10', scheduled_minute: '00'
            },
            schedule: '1'
          }
        }

        it 'still saves the title but does not schedule anything' do
          expect { request }.not_to change { ScheduledPublication.count }

          expect(neighborhood_message_broadcast.reload.title).to eq('new title')
          expect(neighborhood_message_broadcast.status).to eq('draft')
        end
      end
    end
  end

  describe 'GET #new' do
    render_views

    before { get :new }

    it { expect(response.status).to eq(200) }
  end

  describe 'GET #edit slack_id warning' do
    render_views

    let!(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, status: :draft) }

    before { get :edit, params: { id: neighborhood_message_broadcast.id } }

    context 'when the current admin has no slack_id' do
      it { expect(response.body).to include("Ton identifiant Slack n'est pas renseigné") }
    end

    context 'when the current admin has a slack_id' do
      let!(:user) { admin_basic_login.tap { |u| u.update!(slack_id: 'U123') } }

      it { expect(response.body).not_to include("Ton identifiant Slack n'est pas renseigné") }
    end
  end

end
