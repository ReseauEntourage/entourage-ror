require 'rails_helper'
include AuthHelper

describe Admin::ScheduledPublicationsController do
  render_views

  let!(:user) { admin_basic_login }

  around { |example| Sidekiq::Testing.disable!(&example) }

  describe 'GET #index' do
    let!(:post_publication) { create(:scheduled_publication, :post, scheduled_at: 1.day.from_now) }
    let!(:broadcast_publication) { create(:scheduled_publication, :broadcast, scheduled_at: 2.days.from_now) }
    let!(:published_publication) { create(:scheduled_publication, :post, status: :published, scheduled_at: 3.days.ago) }

    context 'with no filter' do
      before { get :index }

      it 'lists all pending scheduled publications, not the already published ones' do
        all = assigns(:grouped_scheduled_publications).values.flatten
        expect(all).to match_array([post_publication, broadcast_publication])
      end
    end

    context 'filtered by post type' do
      before { get :index, params: { type: :post } }

      it { expect(assigns(:grouped_scheduled_publications).values.flatten).to eq([post_publication]) }
    end

    context 'with a failed publication' do
      # @caution a failed publication must stay visible with a way to retry it
      # (EN-9403: "Tu peux réessayer depuis le back-office")
      let!(:failed_publication) { create(:scheduled_publication, :post, status: :failed, scheduled_at: 1.day.ago) }

      before { get :index }

      it 'lists it alongside the pending ones instead of hiding it' do
        all = assigns(:grouped_scheduled_publications).values.flatten
        expect(all).to include(failed_publication)
      end
    end

    context 'filtered by broadcast type' do
      before { get :index, params: { type: :broadcast } }

      it { expect(assigns(:grouped_scheduled_publications).values.flatten).to eq([broadcast_publication]) }
    end

    context 'searching by content' do
      before { get :index, params: { search: post_publication.publishable.content } }

      it { expect(assigns(:grouped_scheduled_publications).values.flatten).to eq([post_publication]) }
    end

    context 'rendering the page' do
      render_views

      before { get :index }

      it { expect(response.status).to eq(200) }

      it 'pluralizes the French summary line correctly' do
        expect(response.body).to include('2 publications programmées')
        expect(response.body).to include('1 post')
        expect(response.body).to include('1 diffusion')
      end
    end

    context 'rendering the page with a recurring item' do
      render_views

      let!(:recurrence_rule) { create(:recurrence_rule) }
      let!(:recurring_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule, scheduled_at: 4.days.from_now) }

      before { get :index }

      it { expect(response.status).to eq(200) }
    end
  end

  describe 'GET #edit' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    before { get :edit, params: { id: scheduled_publication.id } }

    it { expect(response.status).to eq(200) }
    it { expect(assigns(:scheduled_publication)).to eq(scheduled_publication) }
  end

  describe 'PATCH #update' do
    let(:scheduled_publication) { create(:scheduled_publication, :post, scheduled_at: 1.day.from_now) }

    context 'with a valid future date' do
      let(:new_scheduled_at) { 2.days.from_now.change(hour: 9, min: 0) }
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: {
            content: 'nouveau contenu',
            scheduled_date: new_scheduled_at.to_date.strftime('%d/%m/%Y'),
            scheduled_hour: '09',
            scheduled_minute: '00'
          }
        }
      }

      it 'updates the content and the scheduled_at' do
        request

        expect(scheduled_publication.publishable.reload.content).to eq('nouveau contenu')
        expect(scheduled_publication.reload.scheduled_at).to be_within(1.minute).of(new_scheduled_at)
      end

      it 're-schedules the publish job' do
        PublishScheduledPublicationJob.schedule(scheduled_publication)

        request

        job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
        expect(job.at).to be_within(1.minute).of(new_scheduled_at)
      end
    end

    context 'for a previously failed publication' do
      let(:scheduled_publication) { create(:scheduled_publication, :post, status: :failed, scheduled_at: 1.day.ago) }
      let(:new_scheduled_at) { 2.days.from_now.change(hour: 9, min: 0) }
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: {
            content: 'nouveau contenu',
            scheduled_date: new_scheduled_at.to_date.strftime('%d/%m/%Y'),
            scheduled_hour: '09',
            scheduled_minute: '00'
          }
        }
      }

      it 'resets it to pending so the re-scheduled job actually runs' do
        request

        expect(scheduled_publication.reload.status).to eq('pending')
      end
    end

    context 'with a date in the past' do
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: { content: 'foo', scheduled_date: 1.day.ago.to_date.strftime('%d/%m/%Y'), scheduled_hour: '09', scheduled_minute: '00' }
        }
      }

      it 'does not update the scheduled_at' do
        expect { request }.not_to change { scheduled_publication.reload.scheduled_at }
      end
    end

    context 'with a blank content' do
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: { content: '', scheduled_date: 2.days.from_now.to_date.strftime('%d/%m/%Y'), scheduled_hour: '09', scheduled_minute: '00' }
        }
      }

      it 'does not save the change and re-renders the edit form' do
        request

        expect(response).to render_template(:edit)
        expect(scheduled_publication.publishable.reload.content).not_to eq('')
      end
    end

    context 'for a broadcast (cannot be edited through this action)' do
      let(:scheduled_publication) { create(:scheduled_publication, :broadcast, scheduled_at: 1.day.from_now) }
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: { content: 'nouveau contenu', scheduled_date: 2.days.from_now.to_date.strftime('%d/%m/%Y'), scheduled_hour: '09', scheduled_minute: '00' }
        }
      }

      it 'does not modify the broadcast' do
        expect { request }.not_to change { scheduled_publication.publishable.reload.content }
      end

      it 'redirects instead of rendering' do
        request

        expect(response).to have_http_status(:found)
        expect(response.location).to eq(admin_neighborhood_message_broadcasts_url)
      end
    end
  end

  describe 'POST #publish_now' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'publishes immediately and cancels the scheduled job' do
      post :publish_now, params: { id: scheduled_publication.id }

      expect(scheduled_publication.reload.status).to eq('published')
      expect(scheduled_publication.publishable.reload.status).to eq('active')

      job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
      expect(job).to be_nil
    end

    context 'for a broadcast' do
      let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

      it 'sends the broadcast immediately' do
        post :publish_now, params: { id: scheduled_publication.id }

        expect(scheduled_publication.reload.status).to eq('published')
        expect(scheduled_publication.publishable.reload.status).to eq('sent')
      end
    end

    context 'for a previously failed publication (EN-9403: "Tu peux réessayer depuis le back-office")' do
      let(:scheduled_publication) { create(:scheduled_publication, :post, status: :failed, scheduled_at: 1.day.ago) }

      it 'retries it successfully' do
        post :publish_now, params: { id: scheduled_publication.id }

        expect(scheduled_publication.reload.status).to eq('published')
        expect(scheduled_publication.publishable.reload.status).to eq('active')
      end
    end
  end

  describe 'POST #cancel' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'cancels the scheduled publication and soft-deletes the post' do
      post :cancel, params: { id: scheduled_publication.id }

      expect(scheduled_publication.reload.status).to eq('cancelled')
      expect(scheduled_publication.publishable.reload.status).to eq('deleted')
    end

    context 'with a recurring occurrence' do
      let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'daily', ends_on: 1.month.from_now.to_date) }
      let(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule) }

      it 'defaults to cancelling only this occurrence and keeps the series going' do
        expect { post :cancel, params: { id: scheduled_publication.id } }.to change(ScheduledPublication, :count).by(1)
        expect(recurrence_rule.reload.active?).to eq(true)
      end

      it 'cancels the whole series when scope=series' do
        expect { post :cancel, params: { id: scheduled_publication.id, scope: :series } }.not_to change(ScheduledPublication, :count)
        expect(recurrence_rule.reload.active?).to eq(false)
      end
    end

    context 'for a broadcast' do
      let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

      it 'resets the broadcast back to draft' do
        post :cancel, params: { id: scheduled_publication.id }

        expect(scheduled_publication.reload.status).to eq('cancelled')
        expect(scheduled_publication.publishable.reload.status).to eq('draft')
      end
    end
  end
end
