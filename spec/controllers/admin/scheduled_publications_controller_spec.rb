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
            scheduled_date: new_scheduled_at.to_date.to_s,
            scheduled_time: '09:00'
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

    context 'with a date in the past' do
      let(:request) {
        patch :update, params: {
          id: scheduled_publication.id,
          scheduled_publication: { content: 'foo', scheduled_date: 1.day.ago.to_date.to_s, scheduled_time: '09:00' }
        }
      }

      it 'does not update the scheduled_at' do
        expect { request }.not_to change { scheduled_publication.reload.scheduled_at }
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
  end

  describe 'POST #cancel' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'cancels the scheduled publication and soft-deletes the post' do
      post :cancel, params: { id: scheduled_publication.id }

      expect(scheduled_publication.reload.status).to eq('cancelled')
      expect(scheduled_publication.publishable.reload.status).to eq('deleted')
    end
  end
end
