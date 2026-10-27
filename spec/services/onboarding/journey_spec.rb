require 'rails_helper'

describe Onboarding::Journey do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:registered_at) { now - 3.days }
  let!(:user) { create(:public_user, created_at: registered_at, first_sign_in_at: registered_at) }
  let(:journey) { described_class.new(user, now: now) }

  def track(name, at:, properties: nil)
    Event.track(name, user_id: user.id, at: at, properties: properties)
  end

  def removed_events
    Event.where(user_id: user.id, name: 'onboarding.parcours.removed')
  end

  def cross_all_steps(at:)
    track('onboarding.resource.welcome_watched', at: at)
    track('onboarding.neighborhood.national_skipped', at: at)
    track('onboarding.outing.webinar_or_first_steps', at: at)
    track('onboarding.outing.first_event', at: at, properties: { outing_type: 'visio' })
  end

  describe 'steps' do
    {
      'welcome_watched' => ['onboarding.resource.welcome_watched', 'onboarding.resource.welcome_watched_skipped'],
      'neighborhood_national' => ['onboarding.neighborhood.national', 'onboarding.neighborhood.national_skipped'],
      'webinar_or_first_steps' => ['onboarding.outing.webinar_or_first_steps', 'onboarding.outing.webinar_or_first_steps_skipped'],
      'papotages' => ['onboarding.outing.first_event', 'onboarding.outing.papotages_skipped']
    }.each do |step, (done_event, skipped_event)|
      describe step do
        it 'is not crossed by default' do
          expect(journey.done?(step)).to be(false)
          expect(journey.skipped?(step)).to be(false)
          expect(journey.crossed?(step)).to be(false)
        end

        it 'is done and crossed by its event' do
          track(done_event, at: now - 1.day)

          expect(journey.done?(step)).to be(true)
          expect(journey.skipped?(step)).to be(false)
          expect(journey.crossed?(step)).to be(true)
        end

        it 'is skipped and crossed by its skipped event' do
          track(skipped_event, at: now - 1.day)

          expect(journey.done?(step)).to be(false)
          expect(journey.skipped?(step)).to be(true)
          expect(journey.crossed?(step)).to be(true)
        end
      end
    end

    it 'last step is also done by the legacy papotages event' do
      track('onboarding.outing.papotages', at: now - 1.day)

      expect(journey.done?('papotages')).to be(true)
    end

    it 'unknown step raises' do
      expect { journey.done?('foo') }.to raise_error(KeyError)
    end
  end

  describe '#completed?' do
    it 'is false when a step is not crossed' do
      track('onboarding.resource.welcome_watched', at: now - 1.day)
      track('onboarding.neighborhood.national_skipped', at: now - 1.day)
      track('onboarding.outing.webinar_or_first_steps', at: now - 1.day)

      expect(journey.completed?).to be(false)
    end

    it 'is true when the 4 steps are done or skipped' do
      cross_all_steps(at: now - 1.day)

      expect(journey.completed?).to be(true)
    end

    it 'is true when the 4 steps are skipped' do
      track('onboarding.resource.welcome_watched_skipped', at: now - 1.day)
      track('onboarding.neighborhood.national_skipped', at: now - 1.day)
      track('onboarding.outing.webinar_or_first_steps_skipped', at: now - 1.day)
      track('onboarding.outing.papotages_skipped', at: now - 1.day)

      expect(journey.completed?).to be(true)
    end
  end

  describe 'removal' do
    context 'running journey' do
      it { expect(journey.removed?).to be(false) }
      it { expect(journey.removal_reason).to be_nil }
      it { expect(journey.summary).to eq(removed: false, removed_reason: nil) }
    end

    context 'completed' do
      before { cross_all_steps(at: now - 1.day) }

      it { expect(journey.removed?).to be(true) }
      it { expect(journey.removal_reason).to eq('completed') }
      it { expect(journey.summary).to eq(removed: true, removed_reason: 'completed') }
    end

    describe 'inactivity' do
      context 'no step crossed since less than 14 days' do
        let(:registered_at) { now - 13.days }

        it { expect(journey.removed?).to be(false) }
      end

      context 'no step crossed since 14 days' do
        let(:registered_at) { now - 14.days }

        it { expect(journey.removal_reason).to eq('inactivity') }
      end

      context 'a step crossed less than 14 days ago restarts the counter' do
        let(:registered_at) { now - 20.days }

        before { track('onboarding.resource.welcome_watched', at: now - 13.days) }

        it { expect(journey.removed?).to be(false) }
      end

      context 'the counter restarts at each step crossed' do
        let(:registered_at) { now - 25.days }

        before do
          track('onboarding.resource.welcome_watched', at: now - 20.days)
          track('onboarding.neighborhood.national', at: now - 10.days)
        end

        it { expect(journey.removed?).to be(false) }
      end

      context 'last step crossed 14 days ago' do
        let(:registered_at) { now - 25.days }

        before do
          track('onboarding.resource.welcome_watched', at: now - 20.days)
          track('onboarding.neighborhood.national', at: now - 14.days)
        end

        it { expect(journey.removal_reason).to eq('inactivity') }
      end

      context 'a skipped step restarts the counter' do
        let(:registered_at) { now - 20.days }

        before { track('onboarding.outing.papotages_skipped', at: now - 2.days) }

        it { expect(journey.removed?).to be(false) }
      end

      context 'events which are not steps do not restart the counter' do
        let(:registered_at) { now - 20.days }

        before { track('onboarding.chat_messages.welcome.sent', at: now - 2.days) }

        it { expect(journey.removal_reason).to eq('inactivity') }
      end
    end

    describe 'ceiling' do
      context 'registered since less than 30 days' do
        let(:registered_at) { now - 29.days }

        before { track('onboarding.resource.welcome_watched', at: now - 1.day) }

        it { expect(journey.removed?).to be(false) }
      end

      context 'registered since 30 days, with an active member' do
        let(:registered_at) { now - 30.days }

        before { track('onboarding.resource.welcome_watched', at: now - 1.day) }

        it { expect(journey.removal_reason).to eq('ceiling') }
      end

      context 'the earliest condition is the reason' do
        let(:registered_at) { now - 40.days }

        it 'is inactivity when it came first' do
          expect(journey.removal_reason).to eq('inactivity')
        end

        it 'is ceiling when it came first' do
          track('onboarding.resource.welcome_watched', at: now - 20.days)

          expect(journey.removal_reason).to eq('ceiling')
        end
      end

      context 'without first_sign_in_at, the registration date is used' do
        let!(:user) { create(:public_user, created_at: now - 31.days, first_sign_in_at: nil) }

        before { track('onboarding.resource.welcome_watched', at: now - 1.day) }

        it { expect(journey.removal_reason).to eq('ceiling') }
      end
    end

    describe 'persisted removal' do
      it 'keeps the persisted reason' do
        track('onboarding.parcours.removed', at: now - 1.day, properties: { reason: 'hidden' })

        expect(journey.removed?).to be(true)
        expect(journey.removal_reason).to eq('hidden')
      end

      it 'never comes back when a step is crossed after the removal' do
        track('onboarding.parcours.removed', at: now - 10.days, properties: { reason: 'inactivity' })
        track('onboarding.resource.welcome_watched', at: now - 1.day)

        expect(journey.removed?).to be(true)
        expect(journey.removal_reason).to eq('inactivity')
      end

      it 'is removed even without a reason' do
        track('onboarding.parcours.removed', at: now - 1.day)

        expect(journey.removed?).to be(true)
        expect(journey.removal_reason).to be_nil
      end
    end
  end

  describe '#sync!' do
    context 'running journey' do
      it { expect { journey.sync! }.not_to change { Event.count } }
      it { expect(journey.sync!).to be_nil }
    end

    context 'inactivity' do
      let(:registered_at) { now - 20.days }

      it 'persists the removal at the moment the delay expired, once' do
        expect { journey.sync! }.to change { removed_events.count }.by(1)

        event = removed_events.first
        expect(event.properties).to eq('reason' => 'inactivity')
        expect(event.created_at).to be_within(1.second).of(registered_at + 14.days)

        expect { described_class.new(user, now: now).sync! }.not_to change { Event.count }
      end

      it { expect(journey.sync!).to eq('inactivity') }
    end

    context 'ceiling' do
      let(:registered_at) { now - 35.days }

      before { track('onboarding.resource.welcome_watched', at: now - 1.day) }

      it 'persists the reason' do
        journey.sync!

        expect(removed_events.first.properties).to eq('reason' => 'ceiling')
        expect(removed_events.first.created_at).to be_within(1.second).of(registered_at + 30.days)
      end
    end

    context 'completed' do
      before { cross_all_steps(at: now - 2.days) }

      it 'persists the removal when the last step has been crossed' do
        journey.sync!

        expect(removed_events.first.properties).to eq('reason' => 'completed')
        expect(removed_events.first.created_at).to be_within(1.second).of(now - 2.days)
      end
    end

    context 'when something fails' do
      before { allow(Event).to receive(:track).and_raise(StandardError, 'boom') }

      let(:registered_at) { now - 20.days }

      it 'does not raise and reports the error' do
        expect(Sentry).to receive(:capture_exception)

        expect(journey.sync!).to be_nil
      end
    end

    describe 'registration to an event done before the last step was opened to every event' do
      let(:outing_attributes) { { online: false, title: 'Balade au parc', sf_category: :convivialite } }
      let(:outing) { create(:outing, :outing_class, **outing_attributes) }
      let!(:join_request) do
        create(:join_request, joinable: outing, user: user, status: JoinRequest::ACCEPTED_STATUS, created_at: now - 2.days)
      end

      # the observer tracks the step when the registration is created: simulate an older registration
      before { Event.where(user_id: user.id, name: ['onboarding.outing.first_event', 'onboarding.outing.papotages']).delete_all }

      it 'pre-validates the step with the type of the event and the date of the registration' do
        expect { journey.sync! }.to change { Event.where(user_id: user.id, name: 'onboarding.outing.first_event').count }.by(1)

        event = Event.find_by(user_id: user.id, name: 'onboarding.outing.first_event')
        expect(event.properties).to eq('outing_type' => 'physique')
        expect(event.created_at).to be_within(1.second).of(now - 2.days)
        expect(described_class.new(user, now: now).done?('papotages')).to be(true)
      end

      it 'keeps the type of the oldest registration' do
        other = create(:outing, :outing_class, online: true, title: 'Atelier cuisine', sf_category: :convivialite)
        create(:join_request, joinable: other, user: user, status: JoinRequest::ACCEPTED_STATUS, created_at: now - 1.day)
        Event.where(user_id: user.id, name: 'onboarding.outing.first_event').delete_all

        journey.sync!

        expect(Event.find_by(user_id: user.id, name: 'onboarding.outing.first_event').properties).to eq('outing_type' => 'physique')
      end

      it 'is done once' do
        journey.sync!

        expect { described_class.new(user, now: now).sync! }.not_to change { Event.count }
      end

      context 'when the step has been skipped' do
        before { track('onboarding.outing.papotages_skipped', at: now - 1.day) }

        it { expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count } }
      end

      context 'when the registration is pending' do
        let!(:join_request) do
          create(:join_request, joinable: outing, user: user, status: JoinRequest::PENDING_STATUS, created_at: now - 2.days)
        end

        it { expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count } }
      end

      context 'when the registration is to the first steps webinar' do
        let(:outing_attributes) { { online: true, sf_category: :welcome_entourage_local } }

        it { expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count } }
      end

      context 'when the registration is to a neighborhood' do
        let(:outing) { create(:neighborhood) }

        it { expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count } }
      end

      context 'when the journey has already expired' do
        let(:registered_at) { now - 40.days }

        it 'removes it without looking at the history' do
          expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count }
          expect(removed_events.count).to eq(1)
        end
      end

      context 'when the journey is already removed' do
        before { track('onboarding.parcours.removed', at: now - 1.day, properties: { reason: 'hidden' }) }

        it { expect { journey.sync! }.not_to change { Event.where(name: 'onboarding.outing.first_event').count } }
      end
    end
  end

  describe '#hide!' do
    it 'removes the journey with the reason hidden' do
      expect { journey.hide! }.to change { removed_events.count }.by(1)

      expect(removed_events.first.properties).to eq('reason' => 'hidden')
      expect(described_class.new(user, now: now).summary).to eq(removed: true, removed_reason: 'hidden')
    end

    it 'is idempotent and tracks the removal once' do
      journey.hide!

      expect { described_class.new(user, now: now).hide! }.not_to change { Event.count }
    end

    it 'keeps the reason of a journey which had already expired' do
      user.update_columns(created_at: now - 20.days, first_sign_in_at: now - 20.days)

      described_class.new(user, now: now).hide!

      expect(removed_events.count).to eq(1)
      expect(removed_events.first.properties).to eq('reason' => 'inactivity')
    end

    it 'keeps the first reason' do
      journey.hide!
      track('onboarding.resource.welcome_watched', at: now)

      described_class.new(user, now: now + 40.days).hide!

      expect(removed_events.first.properties).to eq('reason' => 'hidden')
    end
  end

  describe '#reminders_allowed?' do
    it 'allows the reminders of every step of a running journey' do
      described_class::STEPS.each_key { |step| expect(journey.reminders_allowed?(step)).to be(true), step }
    end

    it 'forbids the reminders of a skipped step only' do
      track('onboarding.outing.webinar_or_first_steps_skipped', at: now - 1.day)

      expect(journey.reminders_allowed?('webinar_or_first_steps')).to be(false)
      expect(journey.reminders_allowed?('welcome_watched')).to be(true)
    end

    it 'allows the reminders of a step which is done: it is up to the reminder to check' do
      track('onboarding.resource.welcome_watched', at: now - 1.day)

      expect(journey.reminders_allowed?('welcome_watched')).to be(true)
    end

    it 'forbids every reminder once the journey is hidden' do
      journey.hide!

      described_class::STEPS.each_key { |step| expect(described_class.new(user, now: now).reminders_allowed?(step)).to be(false), step }
    end

    context 'expired journey' do
      let(:registered_at) { now - 20.days }

      it { expect(journey.reminders_allowed?('welcome_watched')).to be(false) }
    end

    context 'completed journey' do
      before { cross_all_steps(at: now - 1.day) }

      it { expect(journey.reminders_allowed?('welcome_watched')).to be(false) }
    end
  end

  describe '.remove_expired!' do
    let!(:expired) { create(:public_user, created_at: now - 20.days, first_sign_in_at: now - 20.days) }
    let!(:running) { create(:public_user, created_at: now - 3.days, first_sign_in_at: now - 3.days) }
    let!(:too_old) { create(:public_user, created_at: now - 60.days, first_sign_in_at: now - 60.days) }
    let!(:deleted) { create(:public_user, created_at: now - 20.days, first_sign_in_at: now - 20.days, deleted: true) }
    let!(:already_removed) { create(:public_user, created_at: now - 20.days, first_sign_in_at: now - 20.days) }

    before do
      Event.track('onboarding.parcours.removed', user_id: already_removed.id, at: now - 1.day, properties: { reason: 'hidden' })
    end

    it 'removes the journeys which have expired, of the recent members only' do
      described_class.remove_expired!(now: now)

      expect(Event.where(name: 'onboarding.parcours.removed', user_id: expired.id).pluck(:properties)).to eq([{ 'reason' => 'inactivity' }])
      expect(Event.where(name: 'onboarding.parcours.removed', user_id: running.id)).to be_empty
      expect(Event.where(name: 'onboarding.parcours.removed', user_id: too_old.id)).to be_empty
      expect(Event.where(name: 'onboarding.parcours.removed', user_id: deleted.id)).to be_empty
      expect(Event.where(name: 'onboarding.parcours.removed', user_id: already_removed.id).pluck(:properties)).to eq([{ 'reason' => 'hidden' }])
    end

    it 'is idempotent' do
      described_class.remove_expired!(now: now)

      expect { described_class.remove_expired!(now: now) }.not_to change { Event.count }
    end
  end
end
