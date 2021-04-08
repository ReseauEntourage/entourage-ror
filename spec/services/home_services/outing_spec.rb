require 'rails_helper'

describe HomeServices::Outing do
  let(:user) { FactoryBot.create(:pro_user_paris) }

  describe 'find_all' do
    let!(:outing) { FactoryBot.create(:outing) }
    let!(:second) { FactoryBot.create(:outing) }
    let!(:online) { FactoryBot.create(:outing, online: true) }

    it 'should find online for :offer_help' do
      allow(user).to receive(:goal) { :offer_help }

      outings = HomeServices::Outing.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274).find_all

      expect(outings).to be_kind_of Array
      expect(outings).to match_array([outing, second, online])
    end

    it 'should find no online for :ask_for_help' do
      allow(user).to receive(:goal) { :ask_for_help }

      outings = HomeServices::Outing.new(user: user, latitude: 48.854367553784954, longitude: 2.270340589096274).find_all

      expect(outings).to be_kind_of Array
      expect(outings.count).to eq(2)
      expect(outings).to match_array([outing, second])
    end
  end
end