require 'rails_helper'

RSpec.describe PublishScheduledPublicationJob do
  around { |example| Sidekiq::Testing.disable!(&example) }

  describe '.schedule' do
    let(:scheduled_publication) { create(:scheduled_publication, :post, scheduled_at: 1.hour.from_now) }

    it 'enqueues a tagged job at the scheduled time' do
      PublishScheduledPublicationJob.schedule(scheduled_publication)

      job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
      expect(job).to be_present
      expect(job.at).to be_within(1.second).of(scheduled_publication.scheduled_at)
      expect(job.tags).to include(scheduled_publication.id)
    end
  end

  describe '.cancel' do
    let(:scheduled_publication) { create(:scheduled_publication, :post, scheduled_at: 1.hour.from_now) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'removes the tagged scheduled job' do
      PublishScheduledPublicationJob.cancel(scheduled_publication.id)

      job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
      expect(job).to be_nil
    end
  end

  describe '#perform' do
    let(:scheduled_publication) { create(:scheduled_publication, :post, status: :pending) }

    it 'publishes the underlying post' do
      described_class.new.perform(scheduled_publication.id)

      expect(scheduled_publication.reload.status).to eq('published')
      expect(scheduled_publication.publishable.reload.status).to eq('active')
    end

    context 'when the scheduled publication was already cancelled' do
      before { scheduled_publication.update!(status: :cancelled) }

      it 'does nothing' do
        described_class.new.perform(scheduled_publication.id)

        expect(scheduled_publication.publishable.reload.status).to eq('scheduled')
      end
    end

    context 'when the scheduled publication no longer exists' do
      it 'does nothing' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end
    end
  end
end
