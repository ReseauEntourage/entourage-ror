require 'rails_helper'

describe ScheduledPublication do
  describe 'validations' do
    it { should validate_presence_of(:scheduled_at) }
  end

  describe '#post?' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    it { expect(scheduled_publication.post?).to eq(true) }
    it { expect(scheduled_publication.broadcast?).to eq(false) }
  end

  describe '#broadcast?' do
    let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

    it { expect(scheduled_publication.broadcast?).to eq(true) }
    it { expect(scheduled_publication.post?).to eq(false) }
  end

  describe '.pending' do
    let!(:pending) { create(:scheduled_publication, :post, status: :pending) }
    let!(:published) { create(:scheduled_publication, :post, status: :published) }

    it { expect(ScheduledPublication.pending).to eq([pending]) }
  end

  describe '#in_the_past?' do
    it { expect(build(:scheduled_publication, :post, scheduled_at: 1.day.ago).in_the_past?).to eq(true) }
    it { expect(build(:scheduled_publication, :post, scheduled_at: 1.day.from_now).in_the_past?).to eq(false) }
  end

  describe '#matches_search?' do
    let(:scheduled_publication) { create(:scheduled_publication, :post) }

    before { scheduled_publication.publishable.update!(content: 'Vide-grenier ce week-end') }

    it { expect(scheduled_publication.matches_search?(nil)).to eq(true) }
    it { expect(scheduled_publication.matches_search?('grenier')).to eq(true) }
    it { expect(scheduled_publication.matches_search?('barbecue')).to eq(false) }
  end

  describe '#target_label' do
    it 'returns the neighborhood name for a post' do
      scheduled_publication = create(:scheduled_publication, :post)
      expect(scheduled_publication.target_label).to eq(scheduled_publication.neighborhood.name)
    end

    it 'returns the group count for a broadcast with no targeted group' do
      scheduled_publication = create(:scheduled_publication, :broadcast)
      expect(scheduled_publication.target_label).to eq('0 groupes')
    end

    it 'lists the targeted group names for a broadcast' do
      neighborhood_a = create(:neighborhood, name: 'Groupe A')
      neighborhood_b = create(:neighborhood, name: 'Groupe B')
      scheduled_publication = create(:scheduled_publication, :broadcast)
      scheduled_publication.publishable.update!(conversation_ids: [neighborhood_a.id, neighborhood_b.id])

      expect(scheduled_publication.target_label).to eq('2 groupes : Groupe A, Groupe B')
    end

    it 'truncates the group name list beyond 3 groups' do
      neighborhoods = create_list(:neighborhood, 4)
      scheduled_publication = create(:scheduled_publication, :broadcast)
      scheduled_publication.publishable.update!(conversation_ids: neighborhoods.map(&:id))

      expect(scheduled_publication.target_label).to match(/^4 groupes : .+ et 1 autre$/)
    end
  end

  describe '#recipients_count' do
    it 'returns the neighborhood member count for a post' do
      scheduled_publication = create(:scheduled_publication, :post)
      expect(scheduled_publication.recipients_count).to eq(scheduled_publication.neighborhood.number_of_people)
    end

    it 'returns the sum of members across the targeted groups for a broadcast' do
      neighborhood_a = create(:neighborhood, participants: create_list(:public_user, 2))
      neighborhood_b = create(:neighborhood, participants: create_list(:public_user, 3))
      scheduled_publication = create(:scheduled_publication, :broadcast)
      scheduled_publication.publishable.update!(conversation_ids: [neighborhood_a.id, neighborhood_b.id])

      expected = Neighborhood.where(id: [neighborhood_a.id, neighborhood_b.id]).sum(:number_of_people)
      expect(scheduled_publication.recipients_count).to eq(expected)
      expect(scheduled_publication.recipients_count).to be > 0
    end
  end

  describe '#matches_search? for a broadcast' do
    let(:scheduled_publication) { create(:scheduled_publication, :broadcast) }

    before { scheduled_publication.publishable.update!(title: 'Devenez ambassadeur', content: 'Rejoignez-nous') }

    it { expect(scheduled_publication.matches_search?(nil)).to eq(true) }
    it { expect(scheduled_publication.matches_search?('ambassadeur')).to eq(true) }
    it { expect(scheduled_publication.matches_search?('rejoignez')).to eq(true) }
    it { expect(scheduled_publication.matches_search?('barbecue')).to eq(false) }
  end
end
