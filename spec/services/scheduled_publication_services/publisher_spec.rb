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
      context 'post, on success' do
        let(:scheduled_publication) { create(:scheduled_publication, :post) }

        it 'notifies the author with the exact copy from EN-9403' do
          expect(SlackServices::DirectMessage).to receive(:new) do |args|
            expect(args[:user]).to eq(scheduled_publication.author)
            expect(args[:text]).to start_with("✅ Ta publication programmée vient d'être publiée")
            expect(args[:text]).to include(scheduled_publication.publishable.content(true).truncate(80))
            expect(args[:text]).to match(/Publiée le \d{2}\/\d{2}\/\d{4} à \d{2}:\d{2} dans « #{Regexp.escape(scheduled_publication.neighborhood.name)} »/)
            expect(args[:text]).to include('👉 <')
            expect(args[:text]).to include('|Voir la publication>')

            instance_double(SlackServices::DirectMessage, send!: true)
          end

          described_class.new(scheduled_publication).publish!
        end
      end

      context 'post, on failure' do
        let(:scheduled_publication) { create(:scheduled_publication, :post, scheduled_at: 2.hours.from_now) }

        before { allow_any_instance_of(ChatMessage).to receive(:update!).and_raise(StandardError, 'boom') }

        it 'notifies the author with the distinct failure copy from EN-9403' do
          expect(SlackServices::DirectMessage).to receive(:new) do |args|
            expect(args[:text]).to start_with("⚠️ Ta publication programmée n'a pas pu être publiée")
            expect(args[:text]).to match(/Prévue le \d{2}\/\d{2}\/\d{4} à \d{2}:\d{2} dans «/)
            expect(args[:text]).to include("Elle n'a pas été diffusée. Tu peux réessayer depuis le back-office.")
            expect(args[:text]).to include('👉 <')
            expect(args[:text]).to include('|Ouvrir la publication>')

            instance_double(SlackServices::DirectMessage, send!: true)
          end

          described_class.new(scheduled_publication).publish!
        end
      end

      context 'broadcast, on success' do
        let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

        around { |example| Sidekiq::Testing.fake!(&example) }

        it 'uses the broadcast title and the group count as cible' do
          expect(SlackServices::DirectMessage).to receive(:new) do |args|
            expect(args[:text]).to include(scheduled_publication.publishable.title)
            expect(args[:text]).to match(/dans « \d+ groupes »/)

            instance_double(SlackServices::DirectMessage, send!: true)
          end

          described_class.new(scheduled_publication).publish!
        end
      end
    end
  end
end
