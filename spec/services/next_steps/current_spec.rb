require 'rails_helper'

RSpec.describe NextSteps::Current do
  let(:user) { create(:public_user, travel_distance: 10) }
  let(:nearby) { { latitude: 48.86, longitude: 2.3522 } }

  def locate!
    address = create(:address, user: user, latitude: 48.8566, longitude: 2.3522, postal_code: '75001')
    user.update_column(:address_id, address.id)
    user.reload
  end

  def welcome_journey_over!
    user.update_columns(first_sign_in_at: 40.days.ago, created_at: 40.days.ago)
    user.reload
  end

  def current at: Time.zone.now
    described_class.new(user.reload, now: at)
  end

  before do
    locate!
    create(:user_segment, user: user, engagement_segment: 'Contributeur')
  end

  describe 'a single hero' do
    before { welcome_journey_over! }

    let!(:group) { create(:neighborhood, **nearby) }

    it 'chooses a hero at the first call, displayed now and valid until the start of D+7 in Paris' do
      user.update_columns(goal: 'offer_help')
      now = Time.zone.parse('2026-11-01 10:00 Europe/Paris')
      hero = current(at: now).call

      expect(hero).to have_attributes(kind: 'neighborhood', target_id: group.id, status: 'active', first_displayed_at: now)
      expect(hero.expires_at).to eq(Time.find_zone('Europe/Paris').parse('2026-11-08 00:00'))
      expect(hero).to have_attributes(segment: 'Contributeur', segment_source: 'computed', mode: 'segment', profile: 'offer_help')
    end

    it 'returns the same hero the next day while it is valid' do
      hero = current.call

      expect(current(at: 1.day.from_now).call).to eq(hero)
    end

    it 'replaces a hero first displayed on the 1st from the 8th' do
      hero = current(at: Time.zone.parse('2026-11-01 10:00 Europe/Paris')).call

      expect(current(at: Time.zone.parse('2026-11-07 23:00 Europe/Paris')).call).to eq(hero)

      replacement = current(at: Time.zone.parse('2026-11-08 08:00 Europe/Paris')).call

      expect(hero.reload.status).to eq('expired')
      expect(replacement).to be_present
      expect(replacement).not_to eq(hero)
    end
  end

  describe 'events' do
    before { welcome_journey_over! }

    it 'keeps an event valid until it starts, then stops suggesting it even though the 7 days are not over' do
      starts_at = 2.days.from_now
      event = create(:outing, metadata: { starts_at: starts_at }, **nearby)
      now = Time.zone.now
      hero = current(at: now).call

      expect(hero).to have_attributes(kind: 'outing', target_id: event.id)
      expect(hero.expires_at).to be_within(1.second).of(starts_at)
      expect(current(at: now + 1.day).call).to eq(hero)

      replacement = current(at: starts_at + 1.minute).call

      expect(hero.reload.status).to eq('expired')
      expect(replacement).not_to eq(hero)
    end

    it 'stops suggesting an event that started before the end of its validity, when its date moves up' do
      event = create(:outing, metadata: { starts_at: 5.days.from_now }, **nearby)
      now = Time.zone.now
      hero = current(at: now).call

      Entourage.find(event.id).update_column(:metadata, event.metadata.merge(starts_at: 1.hour.ago))

      expect(current(at: now + 1.minute).call).not_to eq(hero)
      expect(hero.reload.status).to eq('closed')
    end

    it 'does not keep a distant event beyond the 7 days, although it has not started' do
      event = create(:outing, metadata: { starts_at: 20.days.from_now }, **nearby)
      now = Time.zone.now
      hero = current(at: now).call
      end_of_validity = (now.in_time_zone('Europe/Paris').to_date + 7).in_time_zone('Europe/Paris').beginning_of_day

      expect(hero).to have_attributes(kind: 'outing', target_id: event.id)
      expect(hero.expires_at).to eq(end_of_validity)
      expect(current(at: end_of_validity - 1.minute).call).to eq(hero)

      replacement = current(at: end_of_validity + 1.minute).call

      expect(hero.reload.status).to eq('expired')
      expect(replacement).not_to eq(hero)
    end

    it 'replaces a cancelled event at the next call' do
      event = create(:outing, **nearby)
      hero = current.call
      Entourage.find(event.id).update_column(:status, 'cancelled')

      expect(current.call).not_to eq(hero)
      expect(hero.reload.status).to eq('closed')
    end
  end

  describe 'welcome journey' do
    it 'returns no hero while the welcome journey is displayed, and stores nothing' do
      create(:neighborhood, **nearby)

      expect(current.call).to be_nil
      expect(NextStep.count).to eq(0)
    end

    it 'chooses a hero once the welcome journey is removed' do
      create(:neighborhood, **nearby)
      welcome_journey_over!

      expect(current.call).to be_present
    end
  end

  describe 'preview (back-office)' do
    before { welcome_journey_over! }

    let!(:group) { create(:neighborhood, **nearby) }

    it 'returns the hero the call would create, without storing it' do
      preview = current.preview

      expect(preview.state).to eq('to_create')
      expect(preview.next_step).to be_new_record
      expect(preview.next_step).to have_attributes(kind: 'neighborhood', target_id: group.id, segment: 'Contributeur', mode: 'segment')
      expect(NextStep.count).to eq(0)

      expect(current.call).to have_attributes(kind: 'neighborhood', target_id: group.id)
    end

    it 'returns the active hero while it is valid' do
      hero = current.call

      expect(current.preview).to have_attributes(state: 'active', next_step: hero, previous: nil)
    end

    it 'returns the replacement of an expired hero, and leaves the hero active' do
      hero = current(at: 8.days.ago).call
      create(:neighborhood, **nearby)

      preview = current.preview

      expect(preview).to have_attributes(state: 'to_create', previous: hero, previous_status: 'expired')
      expect([preview.next_step.kind, preview.next_step.target_id]).not_to eq([hero.kind, hero.target_id])
      expect(hero.reload.status).to eq('active')
      expect(NextStep.count).to eq(1)
    end

    it 'returns nothing during the welcome journey' do
      user.update_columns(first_sign_in_at: Time.zone.now, created_at: Time.zone.now)

      expect(current.preview).to have_attributes(state: 'welcome_journey', next_step: nil)
    end
  end

  describe 'concurrent calls' do
    before { welcome_journey_over! }

    it 'reads the hero of the call that won the race' do
      create(:neighborhood, **nearby)
      winner = create(:next_step, user: user)
      allow(NextStep).to receive(:active).and_call_original
      allow(NextStep).to receive(:active).and_return(NextStep.none, NextStep.where(id: winner.id))

      expect(current.call).to eq(winner)
    end
  end

  describe 'ignore (5.2)' do
    before { welcome_journey_over! }

    it 'replaces the hero, and keeps the ignored suggestion out of the hero and the others for 30 days' do
      create_list(:neighborhood, 2, **nearby)
      hero = current.call

      replacement = current.ignore!(hero)

      expect(hero.reload.status).to eq('ignored')
      expect(replacement).to be_present
      expect([replacement.kind, replacement.target_id]).not_to eq([hero.kind, hero.target_id])
      expect(current.others.map { |choice| choice.candidate.key }).not_to include([hero.kind, hero.target_type, hero.target_id])

      # 29 days later, the ignored group is still out of the hero
      replacement.ignore!
      expect(NextSteps::Exclusions.new(user, placement: :hero, now: 29.days.from_now).excluded_target_ids('neighborhood')).to include(hero.target_id)
    end
  end

  describe 'realisation (5.3, 5.4)' do
    before { welcome_journey_over! }

    # spec/subscribers/badge_subscriber_spec.rb empties the EventBus subscribers:
    # subscribe here, whatever ran before, and restore them afterwards
    around do |example|
      subscribers = EventBus.instance_variable_get(:@subscribers)
      EventBus.instance_variable_set(:@subscribers, Hash.new { |hash, key| hash[key] = [] })
      NextStepRealisationSubscriber.register!

      example.run
    ensure
      EventBus.instance_variable_set(:@subscribers, subscribers)
    end

    it 'realises the hero when the user joins the proposed event from any screen' do
      event = create(:outing, **nearby)
      hero = current.call

      create(:join_request, user: user, joinable: Entourage.find(event.id), status: :accepted)

      expect(hero.reload.status).to eq('realised')
      expect(current.call).not_to eq(hero)
    end

    it 'does not realise the hero on a simple tap' do
      create(:outing, **nearby)
      hero = current.call

      current.record_interaction!(placement: 'hero', kind: 'tapped', next_step: hero)

      expect(hero.reload.status).to eq('active')
    end

    it 'realises a become-volunteer hero on a tap' do
      user.user_segment.update!(engagement_segment: 'Pilier')
      hero = current.call
      expect(hero.kind).to eq('become_ambassador')

      current.record_interaction!(placement: 'hero', kind: 'tapped', next_step: hero)

      expect(hero.reload.status).to eq('realised')
    end

    it 'never fails the business write when the subscriber raises' do
      event = create(:outing, **nearby)
      current.call
      allow(NextSteps::Realisation).to receive(:realised?).and_raise('boom')
      expect(Sentry).to receive(:capture_exception)

      expect {
        create(:join_request, user: user, joinable: Entourage.find(event.id), status: :accepted)
      }.not_to raise_error
    end
  end

  describe 'operations (7.1, 7.3)' do
    before { welcome_journey_over! }

    it 'falls back on the papotage and reports to Sentry when the selector fails' do
      papotage = create(:outing, online: true, title: 'Papotage solidaire')
      allow_any_instance_of(NextSteps::Selector).to receive(:hero).and_raise('boom')
      expect(Sentry).to receive(:capture_exception)

      expect(current.call.target_id).to eq(papotage.id)
    end

    it 'returns nothing and stores nothing when NEXT_STEPS_ENABLED is false' do
      create(:neighborhood, **nearby)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('NEXT_STEPS_ENABLED', 'true').and_return('false')

      expect(current.call).to be_nil
      expect(current.others).to eq([])
      expect(current.preview.state).to eq('disabled')

      expect(NextStep.count).to eq(0)
    end
  end
end
