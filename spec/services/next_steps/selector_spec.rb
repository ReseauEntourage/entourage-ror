require 'rails_helper'

RSpec.describe NextSteps::Selector do
  let(:user) { create(:public_user, travel_distance: 10) }

  def locate! latitude: 48.8566, longitude: 2.3522
    address = create(:address, user: user, latitude: latitude, longitude: longitude, postal_code: '75001')
    user.update_column(:address_id, address.id)
    user.reload
  end

  def segment! segment, sub_segment = nil
    create(:user_segment, user: user, engagement_segment: segment, engagement_sub_segment: sub_segment)
    user.reload
  end

  def hero previous_kind: nil
    described_class.new(user).hero(previous_kind: previous_kind)
  end

  def target_of choice
    choice.candidate.target
  end

  let(:nearby) { { latitude: 48.86, longitude: 2.3522 } }

  describe 'suggestions by segment' do
    before { locate! }

    it 'suggests a Curieux to post in a group they never wrote in' do
      segment!('Curieux')
      group = create(:neighborhood, participants: [user], **nearby)

      choice = hero

      expect([choice.candidate.kind, target_of(choice)]).to eq(['post_message', group])
    end

    it 'suggests a nearby event to a Dormant' do
      segment!('Silencieux', 'Dormant')
      event = create(:outing, **nearby)
      create(:solicitation, **nearby)

      expect(target_of(hero).id).to eq(event.id)
    end

    it 'falls to the next type when a type has no candidate' do
      segment!('Contributeur')
      group = create(:neighborhood, **nearby)

      expect(target_of(hero)).to eq(group)
    end

    it 'moves the type of the previous hero last, for variety' do
      segment!('Contributeur')
      create(:outing, **nearby)
      group = create(:neighborhood, **nearby)

      expect(target_of(hero(previous_kind: 'outing'))).to eq(group)
    end

    it 'gives a Dormant and a new user different suggestions in the same zone' do
      create(:outing, **nearby)
      create(:solicitation, **nearby)
      segment!('Silencieux', 'Dormant')

      dormant_kind = hero.candidate.kind

      user.user_segment.update!(engagement_segment: 'Silencieux', engagement_sub_segment: 'À activer')
      new_user_kind = described_class.new(user.reload).hero.candidate.kind

      expect([dormant_kind, new_user_kind]).to eq(['outing', 'action'])
    end
  end

  describe 'need mode' do
    before do
      locate!
      segment!('Contributeur')
      create(:outing, **nearby)
    end

    it 'answers a clothes need with an offer of the same section' do
      create(:solicitation, user: user, section_list: ['clothes'], created_at: 5.days.ago, **nearby)
      offer = create(:contribution, section_list: ['clothes'], **nearby)

      choice = hero

      expect([target_of(choice).id, choice.mode, choice.candidate.reason_codes.first]).to eq([offer.id, 'need', 'answers_your_need'])
    end

    it 'answers a hygiene need without offer with a lieu solidaire of the matching category' do
      create(:category, id: 42, name: 'Douches')
      create(:solicitation, user: user, section_list: ['hygiene'], created_at: 5.days.ago, **nearby)
      showers = create(:poi, category_id: 42, **nearby)

      choice = hero

      expect([target_of(choice), choice.candidate.reason_codes.first]).to eq([showers, 'poi_for_need'])
    end

    it 'follows the segment rules when the only need is 45 days old' do
      create(:solicitation, user: user, section_list: ['clothes'], created_at: 45.days.ago, **nearby)
      create(:contribution, section_list: ['clothes'], **nearby)

      expect([hero.mode, hero.candidate.kind]).to eq(['segment', 'outing'])
    end

    it 'never suggests a lieu solidaire without a need' do
      create(:category, id: 42, name: 'Douches')
      create(:poi, category_id: 42, **nearby)
      selector = described_class.new(user)

      expect(([selector.hero] + selector.others).map { |choice| choice.candidate.kind }).not_to include('poi')
    end
  end

  describe 'edge cases and fallbacks' do
    it 'only suggests what needs no place to a user without location' do
      segment!('Contributeur')
      create(:outing, **nearby)
      create(:neighborhood, **nearby)
      online = create(:outing, online: true, title: 'Atelier en visio')

      expect(target_of(hero).id).to eq(online.id)
    end

    it 'suggests the Bonnes ondes when there is neither group nor event, then the papotage' do
      locate!
      segment!('Contributeur')
      papotage = create(:outing, online: true, title: 'Papotage solidaire')

      expect(hero.candidate.kind).to eq('smalltalk')

      create(:user_smalltalk, user: user)

      expect(target_of(described_class.new(user).hero).id).to eq(papotage.id)
    end

    it 'falls back on the papotage for a Curieux who belongs to no group' do
      locate!
      segment!('Curieux')
      papotage = create(:outing, online: true, title: 'Papotage solidaire')

      expect([target_of(hero).id, hero.candidate.reason_codes.first]).to eq([papotage.id, 'papotage'])
    end

    it 'falls back on the Bonnes ondes when no papotage is scheduled' do
      locate!
      segment!('Curieux')

      expect(hero.candidate.kind).to eq('smalltalk')
    end

    it 'suggests nothing when the papotage and the Bonnes ondes are both excluded' do
      locate!
      segment!('Curieux')
      papotage = create(:outing, online: true, title: 'Papotage solidaire')
      create(:join_request, user: user, joinable: Entourage.find(papotage.id), status: :accepted)
      create(:user_smalltalk, user: user, created_at: 10.days.ago)

      expect(hero).to be_nil
    end
  end

  describe 'others' do
    before do
      locate!
      segment!('Contributeur')
    end

    it 'returns up to 3 suggestions of different kinds' do
      create_list(:outing, 2, **nearby)
      create(:neighborhood, **nearby)
      create(:outing, online: true, title: 'Papotage solidaire')

      kinds = described_class.new(user).others.map { |choice| choice.candidate.kind }

      expect(kinds).to eq(['outing', 'neighborhood', 'smalltalk'])
    end

    it 'leaves out a suggestion ignored 10 days ago' do
      group = create(:neighborhood, **nearby)
      create(:next_step, user: user, kind: 'neighborhood', target_type: 'Neighborhood', target_id: group.id,
        status: 'ignored', first_displayed_at: 11.days.ago, ignored_at: 10.days.ago, expires_at: 8.days.ago)

      expect(described_class.new(user).others.map { |choice| choice.candidate.target }).not_to include(group)
    end

    it 'keeps a suggestion seen among the others available as a hero' do
      group = create(:neighborhood, **nearby)

      described_class.new(user).others

      expect(target_of(hero)).to eq(group)
    end

    it 'shows no other date of the series of the hero among the others (4.10)' do
      first = create(:outing, recurrency_identifier: 'serie-a', metadata: { starts_at: 3.days.from_now }, **nearby)
      create(:outing, recurrency_identifier: 'serie-a', metadata: { starts_at: 10.days.from_now }, **nearby)
      create(:next_step, user: user, kind: 'outing', target_type: 'Outing', target_id: first.id,
        status: 'active', first_displayed_at: Time.current, expires_at: 2.days.from_now)

      kinds = described_class.new(user).others.map { |choice| choice.candidate.kind }

      expect(kinds).not_to include('outing')
    end

    it 'never shows two types of suggestions that belong to the same series (4.10)' do
      create(:outing, recurrency_identifier: 'serie-a', online: true, title: 'Atelier en visio', metadata: { starts_at: 2.days.from_now })
      create(:outing, recurrency_identifier: 'serie-a', online: true, title: 'Papotage solidaire', metadata: { starts_at: 5.days.from_now })

      outings = described_class.new(user).others.select { |choice| choice.candidate.kind == 'outing' }

      expect(outings.map { |choice| choice.candidate.target.title }).to eq(['Atelier en visio'])
    end
  end
end
