require 'rails_helper'

describe ScheduledPublicationServices::RecurrenceGenerator do
  around { |example| Sidekiq::Testing.disable!(&example) }

  describe '#generate_next!' do
    context 'post, within the recurrence window' do
      let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'daily', ends_on: 1.month.from_now.to_date) }
      let!(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule, scheduled_at: 1.day.from_now) }

      it 'creates and schedules the next occurrence as a new scheduled ChatMessage' do
        expect { described_class.new(scheduled_publication).generate_next! }
          .to change(ChatMessage, :count).by(1)
          .and change(ScheduledPublication, :count).by(1)

        next_scheduled_publication = ScheduledPublication.last
        expect(next_scheduled_publication.scheduled_at).to be_within(1.second).of(scheduled_publication.scheduled_at + 1.day)
        expect(next_scheduled_publication.publishable.content).to eq(scheduled_publication.publishable.content)
        expect(next_scheduled_publication.publishable.status).to eq('scheduled')
        expect(next_scheduled_publication.neighborhood).to eq(scheduled_publication.neighborhood)
        expect(next_scheduled_publication.recurrence_rule).to eq(recurrence_rule)
      end

      it 'schedules a sidekiq job for the next occurrence' do
        described_class.new(scheduled_publication).generate_next!

        next_scheduled_publication = ScheduledPublication.last
        job = Sidekiq::ScheduledSet.new.find { |j| j.args.first == next_scheduled_publication.id }
        expect(job).to be_present
      end
    end

    context 'broadcast, within the recurrence window' do
      let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'weekly', ends_on: 2.months.from_now.to_date) }
      let!(:scheduled_publication) { create(:scheduled_publication, :broadcast, recurrence_rule: recurrence_rule, scheduled_at: 1.day.from_now) }

      it 'creates and schedules the next occurrence as a new scheduled broadcast' do
        expect { described_class.new(scheduled_publication).generate_next! }
          .to change(NeighborhoodMessageBroadcast, :count).by(1)
          .and change(ScheduledPublication, :count).by(1)

        next_scheduled_publication = ScheduledPublication.last
        expect(next_scheduled_publication.publishable.status).to eq('scheduled')
        expect(next_scheduled_publication.publishable.title).to eq(scheduled_publication.publishable.title)
      end
    end

    context 'past the recurrence end date' do
      let!(:recurrence_rule) { create(:recurrence_rule, frequency: 'daily', ends_on: Date.today) }
      let!(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule, scheduled_at: 1.day.from_now) }

      it 'does not create a next occurrence' do
        expect { described_class.new(scheduled_publication).generate_next! }.not_to change(ScheduledPublication, :count)
      end
    end

    context 'when the series was deactivated' do
      let!(:recurrence_rule) { create(:recurrence_rule, active: false) }
      let!(:scheduled_publication) { create(:scheduled_publication, :post, recurrence_rule: recurrence_rule) }

      it 'does not create a next occurrence' do
        expect { described_class.new(scheduled_publication).generate_next! }.not_to change(ScheduledPublication, :count)
      end
    end

    context 'when there is no recurrence rule' do
      let!(:scheduled_publication) { create(:scheduled_publication, :post) }

      it 'does nothing' do
        expect { described_class.new(scheduled_publication).generate_next! }.not_to change(ScheduledPublication, :count)
      end
    end
  end
end
