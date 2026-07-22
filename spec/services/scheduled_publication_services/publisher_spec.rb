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

    context 'slack notification' do
      let(:scheduled_publication) { create(:scheduled_publication, :post) }

      it 'notifies the author of the successful publication' do
        expect(SlackServices::DirectMessage).to receive(:new)
          .with(hash_including(user: scheduled_publication.author))
          .and_return(instance_double(SlackServices::DirectMessage, send!: true))

        described_class.new(scheduled_publication).publish!
      end

      it 'notifies the author with a distinct message when publishing fails' do
        allow_any_instance_of(ChatMessage).to receive(:update!).and_raise(StandardError, 'boom')

        expect(SlackServices::DirectMessage).to receive(:new) do |args|
          expect(args[:text]).to match(/Échec/)
          instance_double(SlackServices::DirectMessage, send!: true)
        end

        described_class.new(scheduled_publication).publish!
      end
    end

    context 'recurring post' do
      let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'daily', ends_on: 1.month.from_now.to_date) }
      let!(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule) }

      around { |example| Sidekiq::Testing.disable!(&example) }

      it 'schedules the next occurrence after a successful publish' do
        expect { described_class.new(scheduled_publication).publish! }.to change(ScheduledPublication, :count).by(1)
      end

      it 'still schedules the next occurrence when publishing fails, so one bad occurrence does not break the series' do
        allow_any_instance_of(ChatMessage).to receive(:update!).and_raise(StandardError, 'boom')

        expect { described_class.new(scheduled_publication).publish! }.to change(ScheduledPublication, :count).by(1)
        expect(scheduled_publication.reload.status).to eq('failed')
      end
    end
  end
end
