require 'rails_helper'

describe MatchingServices::Candidates do
  let(:paris) { { latitude: 48.86, longitude: 2.35 } }
  let(:lyon) { { latitude: 45.76, longitude: 4.83 } }

  let(:user) { create(:ask_for_help_user) }
  let(:other_user) { create(:offer_help_user) }
  let(:action) { create(:solicitation, user: user, title: 'Besoin de vêtements', section_list: ['clothes'], **paris) }

  subject(:candidates) { described_class.new(action).all }

  def ids_of type
    candidates.select { |candidate| candidate.type == type }.map { |candidate| candidate.record.id }
  end

  describe 'opposite actions' do
    let!(:near_contribution) { create(:contribution, user: other_user, title: 'Je donne un manteau', section_list: ['clothes'], latitude: 48.87, longitude: 2.36) }
    let!(:far_contribution) { create(:contribution, user: other_user, **lyon) }
    let!(:own_contribution) { create(:contribution, user: user, **paris) }
    let!(:near_solicitation) { create(:solicitation, user: other_user, **paris) }
    let!(:old_contribution) { create(:contribution, user: other_user, created_at: 2.months.ago, **paris) }

    it 'keeps the actions of the opposite type, around the action, from other users, of the last 30 days' do
      expect(ids_of('contribution')).to eq([near_contribution.id])
      expect(ids_of('solicitation')).to be_empty
    end

    it 'computes the distance, the freshness and the category match' do
      candidate = candidates.find { |candidate| candidate.record == near_contribution }

      expect(candidate.distance_km).to be_within(0.2).of(1.3)
      expect(candidate.freshness).to be > 0.9
      expect(candidate.category_match).to be(true)
    end
  end

  describe 'outings' do
    let!(:near_outing) { create(:outing, user: other_user, **paris) }
    let!(:far_outing) { create(:outing, user: other_user, **lyon) }
    let!(:past_outing) { create(:outing, user: other_user, default_metadata: { starts_at: 2.days.ago, ends_at: 2.days.ago + 2.hours, place_name: 'Café', street_address: 'Paris', google_place_id: 'foobar' }, **paris) }

    it 'keeps the upcoming outings around the action' do
      expect(ids_of('outing')).to eq([near_outing.id])
    end
  end

  describe 'neighborhoods' do
    let!(:near_neighborhood) { create(:neighborhood, user: other_user, **paris) }
    let!(:far_neighborhood) { create(:neighborhood, user: other_user, **lyon) }

    it 'keeps the neighborhoods around the action' do
      expect(ids_of('neighborhood')).to eq([near_neighborhood.id])
    end

    context 'with national, joined and private neighborhoods' do
      let!(:national_neighborhood) { create(:neighborhood, user: other_user, national: true, **lyon) }
      let!(:joined_neighborhood) { create(:neighborhood, user: other_user, participants: [user], **paris) }
      let!(:private_neighborhood) { create(:neighborhood, user: other_user, public: false, **paris) }

      it 'keeps the national neighborhoods and leaves out the joined and private ones' do
        expect(ids_of('neighborhood')).to match_array([near_neighborhood.id, national_neighborhood.id])
      end
    end

    context 'with several neighborhoods around the action' do
      let!(:closer_neighborhood) { create(:neighborhood, user: other_user, latitude: 48.8601, longitude: 2.3501) }

      before { near_neighborhood.update_columns(latitude: 48.875, longitude: 2.37) }

      it 'sorts them by proximity' do
        expect(ids_of('neighborhood')).to eq([closer_neighborhood.id, near_neighborhood.id])
      end
    end
  end

  describe 'pois' do
    let(:clothes) { create(:category, id: 61, name: 'Vêtements, matériel') }
    let(:food) { create(:category, id: 1, name: 'Se nourrir') }
    let!(:clothes_poi) { create(:poi, category: clothes, latitude: 48.87, longitude: 2.36) }
    let!(:food_poi) { create(:poi, category: food, **paris) }
    let!(:far_poi) { create(:poi, category: clothes, **lyon) }

    it 'keeps the validated points of interest around the action, closest first' do
      expect(ids_of('poi')).to eq([food_poi.id, clothes_poi.id])
    end

    context 'when a point of interest is further than 5 km' do
      let!(:suburb_poi) { create(:poi, category: clothes, latitude: 48.80, longitude: 2.45) }

      it { expect(ids_of('poi')).not_to include(suburb_poi.id) }
    end

    it 'matches the categories of points of interest with the sections of the action' do
      expect(candidates.find { |candidate| candidate.record == clothes_poi }.category_match).to be(true)
      expect(candidates.find { |candidate| candidate.record == food_poi }.category_match).to be(false)
    end

    context 'when the user offers help' do
      let(:user) { create(:offer_help_user) }
      let(:action) { create(:contribution, user: user, **paris) }

      it { expect(ids_of('poi')).to be_empty }
    end
  end

  describe 'resources' do
    let!(:pinned_resource) { create(:resource, pin_ask_for_help: true) }
    let!(:resource) { create(:resource) }

    context 'when a description embeds an image' do
      let!(:resource) { create(:resource, description: %(<p>Bien donner</p><img src="data:image/png;base64,#{'A' * 1000}"/>)) }

      it 'does not load the image' do
        record = candidates.find { |candidate| candidate.record.id == resource.id }.record

        expect(record.description).to eq('<p>Bien donner</p><img src=""/>')
        expect(record.text_description_only).to eq('Bien donner')
      end
    end

    it 'keeps all the active resources and favours the ones pinned for the profile of the user' do
      expect(ids_of('resource')).to match_array([pinned_resource.id, resource.id])
      expect(candidates.find { |candidate| candidate.record == pinned_resource }.category_match).to be(true)
      expect(candidates.find { |candidate| candidate.record == resource }.category_match).to be(false)
    end
  end
end
