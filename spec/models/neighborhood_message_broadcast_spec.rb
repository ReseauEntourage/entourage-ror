require 'rails_helper'

RSpec.describe NeighborhoodMessageBroadcast, type: :model do
  it { should validate_presence_of(:content) }
  it { should validate_presence_of(:title) }

  let!(:neighborhood_75009) { create(:neighborhood, postal_code: '75009') }
  let!(:neighborhood_75018) { create(:neighborhood, postal_code: '75018') }
  let!(:neighborhood_44240) { create(:neighborhood, postal_code: '44240') }
  let!(:neighborhood_29160) { create(:neighborhood, postal_code: '29160') }

  describe 'departements' do
    let(:conversation_ids) { [] }
    let(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, conversation_ids: conversation_ids) }

    let(:subject) { neighborhood_message_broadcast.departements }

    context 'finds single departement from multiple postal_codes of that departement' do
      let(:conversation_ids) { [neighborhood_75009.id, neighborhood_75018.id] }

      it { expect(subject).to match_array(['75']) }
    end

    context 'finds multiple departements from postal_codes of multiple departements' do
      let(:conversation_ids) { [neighborhood_75009.id, neighborhood_44240.id] }

      it { expect(subject).to match_array(['75', '44']) }
    end
  end

  describe 'neighborhood_ids_in_departements' do
    let(:departements) { [] }

    let(:subject) { NeighborhoodMessageBroadcast::neighborhood_ids_in_departements(departements) }

    context 'finds no neighborhood when unexisting departement' do
      let(:departements) { ['35'] }

      it { expect(subject).to match_array([]) }
    end

    context 'finds all departements of single departement' do
      let(:departements) { ['75'] }

      it { expect(subject).to match_array([neighborhood_75009.id, neighborhood_75018.id]) }
    end

    context 'finds all departements of multiple departements' do
      let(:departements) { ['75', '44'] }

      it { expect(subject).to match_array([neighborhood_75009.id, neighborhood_75018.id, neighborhood_44240.id]) }
    end
  end

  describe 'has_full_departements_selection?' do
    let(:conversation_ids) { [] }
    let(:neighborhood_message_broadcast) { create(:neighborhood_message_broadcast, conversation_ids: conversation_ids) }

    let(:subject) { neighborhood_message_broadcast.has_full_departements_selection? }

    context 'empty broadcast' do
      it { expect(subject).to eq(true) }
    end

    context 'one neighborhood in departement and one set on broadcast' do
      let(:conversation_ids) { [neighborhood_44240.id] }

      it { expect(subject).to eq(true) }
    end

    context 'multiple neighborhoods in departement but only one set on broadcast' do
      let(:conversation_ids) { [neighborhood_75009.id] }

      it { expect(subject).to eq(false) }
    end

    context 'multiple neighborhoods in departement and all set on broadcast' do
      let(:conversation_ids) { [neighborhood_75009.id, neighborhood_75018.id] }

      it { expect(subject).to eq(true) }
    end

    context 'multiple neighborhoods in mulitple departements and all set on broadcast' do
      let(:conversation_ids) { [neighborhood_75009.id, neighborhood_75018.id, neighborhood_44240.id] }

      it { expect(subject).to eq(true) }
    end

    context 'multiple neighborhoods in mulitple departements but one is missing on broadcast' do
      let(:conversation_ids) { [neighborhood_75009.id, neighborhood_44240.id] }

      it { expect(subject).to eq(false) }
    end
  end
end
