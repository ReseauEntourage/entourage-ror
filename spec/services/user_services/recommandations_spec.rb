require 'rails_helper'

describe UserServices::Recommandations do
  let(:user) { FactoryBot.create(:pro_user) }
  let(:subject) { UserServices::Recommandations.new(user: user) }

  describe 'find' do
    let!(:neighborhood) { FactoryBot.create(:neighborhood) }

    context 'empty result' do
      it { expect(subject.find).to eq([]) }
    end

    context 'with recommandations' do
      let!(:recommandation) { FactoryBot.create(:recommandation, name: 'voisinage', instance: :neighborhood, action: :show) }
      it { expect(subject.find).to match([recommandation]) }
      it { expect(subject.find.first.instance_key).to eq(:id) }
      it { expect(subject.find.first.instance_id).to eq(neighborhood.id) }
    end
  end
end
