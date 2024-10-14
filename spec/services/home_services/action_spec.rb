require 'rails_helper'

describe HomeServices::Action do
  let(:user) { FactoryBot.create(:pro_user_paris) }

  # action coordinates: 1.122, 2.345
  let!(:ask_for_help) { FactoryBot.create(:entourage, entourage_type: :ask_for_help, title: 'ask_for_help') }
  let!(:contribution) { FactoryBot.create(:entourage, entourage_type: :contribution, title: 'contribution') }

  describe 'find_all' do
    # 5,57km from action
    let(:subject) { HomeServices::Action.new(user: user, latitude: 1.1, longitude: 2.3) }

    it 'should find actions within user travel_distance' do
      user.update_attribute(:travel_distance, 8)

      expect(subject.find_all).to eq([ask_for_help, contribution])
    end

    it 'should not find actions outside user travel_distance' do
      user.update_attribute(:travel_distance, 1)

      expect(subject.find_all.count).to eq(0)
    end

    it 'ask_for_help firsts for :offer_help' do
      allow(user).to receive(:goal) { :offer_help }

      expect(subject.find_all).to eq([ask_for_help, contribution])
    end

    it 'contribution firsts for :ask_for_help' do
      allow(user).to receive(:goal) { :ask_for_help }

      expect(subject.find_all).to eq([contribution, ask_for_help])
    end

    it 'no ask_for_help if entourage_type is contribution' do
      expect(subject.find_all(entourage_type: :contribution)).to eq([contribution])
    end

    it 'no contribution if entourage_type is ask_for_help' do
      expect(subject.find_all(entourage_type: :ask_for_help)).to eq([ask_for_help])
    end
  end
end
