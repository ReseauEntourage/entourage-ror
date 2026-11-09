require 'rails_helper'

RSpec.describe NextSteps::Providers do
  let(:user) { create(:public_user, travel_distance: 10) }
  let(:need) { nil }

  def locate! user, latitude: 48.8566, longitude: 2.3522
    address = create(:address, user: user, latitude: latitude, longitude: longitude, postal_code: '75001')
    user.update_column(:address_id, address.id)
    user.reload
  end

  def providers placement: :hero
    described_class.new(user, NextSteps::Exclusions.new(user, placement: placement), need: need)
  end

  def targets type
    providers.candidates(type).map(&:target)
  end

  describe 'events (4.2)' do
    before { locate!(user) }

    let!(:far) { create(:outing, latitude: 48.93, longitude: 2.3522) } # ~8 km
    let!(:near) { create(:outing, latitude: 48.86, longitude: 2.3522) }
    let!(:online) { create(:outing, online: true, title: 'Atelier en visio') }
    let!(:papotage) { create(:outing, online: true, title: 'Papotage solidaire') }

    it 'lists the in-person events of the zone, closest first, then the online events, without papotages' do
      expect(targets('outing').map(&:id)).to eq([near.id, far.id, online.id])
    end

    it 'leaves out the events the user joined or organizes' do
      create(:join_request, user: user, joinable: Entourage.find(near.id), status: :accepted)
      create(:outing, user: user, latitude: 48.86, longitude: 2.3522)

      expect(targets('outing').map(&:id)).to eq([far.id, online.id])
    end

    it 'never suggests a women-only event to a man, papotages included' do
      user.update!(gender: 'male')
      women_only = create(:outing, :outing_class, latitude: 48.86, longitude: 2.3522, reserved_female: true)
      women_papotage = create(:outing, :outing_class, online: true, title: 'Papotage entre femmes', reserved_female: true)

      expect(targets('outing').map(&:id)).not_to include(women_only.id)
      expect(targets('papotage').map(&:id)).not_to include(women_papotage.id)
    end

    it 'still suggests a women-only event to a woman' do
      user.update!(gender: 'female')
      women_only = create(:outing, :outing_class, latitude: 48.86, longitude: 2.3522, reserved_female: true)

      expect(targets('outing').map(&:id)).to include(women_only.id)
    end

    it 'lists the papotages as their own type' do
      expect(targets('papotage').map(&:id)).to eq([papotage.id])
    end

    it 'recognizes a papotage by its category too' do
      tagged = create(:outing, :outing_class, online: true, title: 'Moment convivial', sf_category: 'papotages')

      expect(targets('papotage').map(&:id)).to contain_exactly(papotage.id, tagged.id)
    end

    it 'only lists online events for a user without location' do
      user.update_column(:address_id, nil)
      user.reload

      expect(targets('outing').map(&:id)).to eq([online.id])
      expect(targets('outing_nearby')).to be_empty
    end
  end

  describe 'groups (4.3)' do
    before { locate!(user) }

    it 'lists the groups of the zone the user is not a member of' do
      local = create(:neighborhood, latitude: 48.86, longitude: 2.35)
      joined = create(:neighborhood, latitude: 48.86, longitude: 2.35, participants: [user])

      expect(targets('neighborhood')).to eq([local])
      expect(targets('neighborhood')).not_to include(joined)
    end

    it 'falls back on national groups sharing an interest when no group of the zone fits' do
      user.update!(interest_list: ['sport'])
      national = create(:neighborhood, national: true, interest_list: ['sport'], latitude: 0, longitude: 0)
      create(:neighborhood, national: true, interest_list: ['cuisine'], latitude: 0, longitude: 0)

      expect(targets('neighborhood')).to eq([national])
    end
  end

  describe 'entraides (4.4)' do
    before { locate!(user) }

    let!(:solicitation) { create(:solicitation, latitude: 48.86, longitude: 2.3522) }
    let!(:contribution) { create(:contribution, latitude: 48.86, longitude: 2.3522) }

    it 'suggests requests to a riverain' do
      expect(targets('action').map(&:id)).to eq([solicitation.id])
    end

    it 'suggests offers to a person in precarity' do
      user.update_columns(goal: 'ask_for_help', targeting_profile: nil)

      expect(targets('action').map(&:id)).to eq([contribution.id])
    end

    it 'leaves out the entraides of a user in a block relation' do
      create(:user_blocked_user, user: solicitation.user, blocked_user: user)

      expect(targets('action')).to be_empty
    end

    it 'leaves out an entraide already answered in a private conversation' do
      conversation = create(:conversation, user: user, participants: [user, solicitation.user])
      create(:chat_message, messageable: conversation, user: user)

      expect(targets('action')).to be_empty
    end

    it 'suggests no entraide to a user without location' do
      user.update_column(:address_id, nil)
      user.reload

      expect(targets('action')).to be_empty
    end
  end

  describe 'contents (4.5)' do
    let!(:resources) { create_list(:resource, 4) }

    it 'offers 3 unread contents, those pinned for the profile first' do
      resources.last.update_column(:pin_offer_help, true)

      expect(providers.candidates('content_path').first.target_ids).to eq([resources[3].id, resources[0].id, resources[1].id])
    end

    it 'never offers a content already read' do
      create(:users_resource, user: user, resource: resources.first, watched: true)

      expect(providers.candidates('content_path').first.target_ids).not_to include(resources.first.id)
    end

    it 'offers no path when fewer than 3 contents are unread' do
      resources.first(2).each { |resource| create(:users_resource, user: user, resource: resource, watched: true) }

      expect(providers.candidates('content_path')).to be_empty
    end
  end

  describe 'gestures (4.6)' do
    it 'never suggests becoming Animateur to an Animateur' do
      user.update_column(:targeting_profile, 'ambassador')

      expect(providers.candidates('become_ambassador')).to be_empty
    end

    it 'suggests becoming Animateur to anybody else' do
      expect(providers.candidates('become_ambassador').map(&:kind)).to eq(['become_ambassador'])
    end

    it 'suggests posting in a group the user is a member of and never wrote in' do
      silent = create(:neighborhood, participants: [user])
      written = create(:neighborhood, participants: [user])
      create(:chat_message, messageable: written, user: user)

      expect(targets('post_message')).to eq([silent])
    end

    it 'does not suggest the Bonnes ondes requested 10 days ago' do
      create(:user_smalltalk, user: user, created_at: 10.days.ago)

      expect(providers.candidates('smalltalk')).to be_empty
    end

    it 'suggests the Bonnes ondes again 30 days after the last request' do
      create(:user_smalltalk, user: user, created_at: 40.days.ago)

      expect(providers.candidates('smalltalk').map(&:kind)).to eq(['smalltalk'])
    end
  end

  describe 'lieux solidaires (4.7)' do
    before do
      locate!(user)
      create(:category, id: 42, name: 'Douches')
      create(:category, id: 61, name: 'Vêtements, matériel')
    end

    let!(:showers) { create(:poi, category_id: 42, latitude: 48.86, longitude: 2.3522) }
    let!(:clothes) { create(:poi, category_id: 61, latitude: 48.86, longitude: 2.3522) }

    context 'with a hygiene need' do
      let(:need) { NextSteps::Need.new(sections: ['hygiene'], solicitation_id: 1, title: 'Savon') }

      it 'suggests a lieu of the matching category' do
        expect(targets('poi')).to eq([showers])
      end
    end

    it 'suggests no lieu without a need' do
      expect(targets('poi')).to be_empty
    end
  end
end
