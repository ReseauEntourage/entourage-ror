require 'rails_helper'

describe HomeServices::Outing do
  let(:user) { FactoryBot.create(:pro_user_paris) }

  describe 'find_all' do
    # outing coordinates: (48.854367553785, 2.27034058909627)
    let!(:outing) { FactoryBot.create(:outing) }
    let!(:second) { FactoryBot.create(:outing) }
    let!(:online) { FactoryBot.create(:outing, online: true) }

    # 3,092km from outing
    let(:subject) { HomeServices::Outing.new(user: user, latitude: 48.83, longitude: 2.25) }

    it 'should find outings within user travel_distance' do
      user.update_attribute(:travel_distance, 8)

      expect(subject.find_all).to match_array([outing, second, online])
    end

    it 'should not find outings outside user travel_distance' do
      user.update_attribute(:travel_distance, 2)

      expect(subject.find_all).to eq([online])
    end

    it 'should find online for :offer_help' do
      allow(user).to receive(:goal) { :offer_help }

      outings = subject.find_all

      expect(outings).to be_kind_of Array
      expect(outings).to match_array([outing, second, online])
    end

    it 'should find no online for :ask_for_help' do
      allow(user).to receive(:goal) { :ask_for_help }

      outings = subject.find_all

      expect(outings).to be_kind_of Array
      expect(outings.count).to eq(2)
      expect(outings).to match_array([outing, second])
    end

    it 'should order by starts_at' do
      allow(user).to receive(:goal) { :ask_for_help }
      outing.metadata[:starts_at] = Time.zone.now + 1.hour and outing.save
      second.metadata[:starts_at] = Time.zone.now + 1.minute and second.save

      outings = subject.find_all

      expect(outings).to be_kind_of Array
      expect(outings.count).to eq(2)
      expect(outings).to match_array([second, outing])
    end
  end
end
