require 'rails_helper'

describe ScheduledPublicationServices::Canceller do
  describe '#cancel!' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    around { |example| Sidekiq::Testing.disable!(&example) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'soft-deletes the underlying post and marks the scheduled publication as cancelled' do
      described_class.new(scheduled_publication).cancel!

      expect(scheduled_publication.publishable.reload.status).to eq('deleted')
      expect(scheduled_publication.reload.status).to eq('cancelled')
    end

    it 'removes the pending sidekiq job' do
      described_class.new(scheduled_publication).cancel!

      job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == scheduled_publication.id }
      expect(job).to be_nil
    end
  end

  describe '#cancel! for a recurring occurrence' do
    let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'daily', ends_on: 1.month.from_now.to_date) }
    let!(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule) }

    around { |example| Sidekiq::Testing.disable!(&example) }

    context 'scope: :occurrence (default)' do
      it 'cancels only this occurrence and still schedules the next one' do
        expect { described_class.new(scheduled_publication).cancel! }.to change(ScheduledPublication, :count).by(1)

        expect(scheduled_publication.reload.status).to eq('cancelled')
        expect(recurrence_rule.reload.active?).to eq(true)
      end
    end

    context 'scope: :series' do
      it 'cancels this occurrence and deactivates the series, without scheduling a next one' do
        expect { described_class.new(scheduled_publication, scope: :series).cancel! }.not_to change(ScheduledPublication, :count)

        expect(scheduled_publication.reload.status).to eq('cancelled')
        expect(recurrence_rule.reload.active?).to eq(false)
      end
    end
  end

  describe '#cancel! for a broadcast' do
    let(:scheduled_publication) { create(:scheduled_publication, :broadcast, scheduled_at: 1.hour.from_now) }

    around { |example| Sidekiq::Testing.disable!(&example) }

    before { PublishScheduledPublicationJob.schedule(scheduled_publication) }

    it 'resets the broadcast back to draft' do
      described_class.new(scheduled_publication).cancel!

      broadcast = scheduled_publication.publishable.reload
      expect(broadcast.status).to eq('draft')
      expect(broadcast.scheduled_at).to be_nil
      expect(scheduled_publication.reload.status).to eq('cancelled')
    end
  end
end
