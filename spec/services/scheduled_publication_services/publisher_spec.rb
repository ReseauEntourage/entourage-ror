require 'rails_helper'

describe ScheduledPublicationServices::Publisher do
  describe '#publish!' do
    context 'post' do
      let(:scheduled_publication) { create(:scheduled_publication, :post) }

      it 'activates the chat message and updates its created_at' do
        described_class.new(scheduled_publication).publish!

        expect(scheduled_publication.publishable.reload.status).to eq('active')
        expect(scheduled_publication.reload.status).to eq('published')
      end

      it 'moves created_at to the actual publication time so the post ranks at the top of the feed' do
        scheduled_publication.publishable.update!(created_at: 3.days.ago)
        original_created_at = scheduled_publication.publishable.reload.created_at

        described_class.new(scheduled_publication).publish!

        expect(scheduled_publication.publishable.reload.created_at).to be > original_created_at
      end
    end

    context 'broadcast' do
      let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

      around { |example| Sidekiq::Testing.fake!(&example) }

      it 'marks the broadcast as sent and enqueues the recipient jobs' do
        described_class.new(scheduled_publication).publish!

        expect(scheduled_publication.publishable.reload.status).to eq('sent')
        expect(scheduled_publication.reload.status).to eq('published')
      end
    end

    context 'when publishing fails' do
      let(:scheduled_publication) { create(:scheduled_publication, :post) }

      before { allow_any_instance_of(ChatMessage).to receive(:update!).and_raise(StandardError, 'boom') }

      it 'marks the scheduled publication as failed' do
        described_class.new(scheduled_publication).publish!

        expect(scheduled_publication.reload.status).to eq('failed')
        expect(scheduled_publication.reload.failure_reason).to eq('boom')
      end
    end
  end
end
