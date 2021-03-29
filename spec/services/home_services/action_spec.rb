require 'rails_helper'

describe HomeServices::Action do
  let(:user) { FactoryGirl.create(:pro_user_paris) }
  let!(:ask_for_help) { FactoryGirl.create(:entourage, entourage_type: :ask_for_help, title: 'ask_for_help') }
  let!(:contribution) { FactoryGirl.create(:entourage, entourage_type: :contribution, title: 'contribution') }
  let!(:pin) { FactoryGirl.create(:entourage, pin: true, pins: '75', title: 'pin') }

  describe 'find_all' do
    it 'ask_for_help firsts for :offer_help' do
      allow(user).to receive(:goal) { :offer_help }

      actions = HomeServices::Action.new(user: user, latitude: 1.122, longitude: 2.345).find_all

      expect(actions).to eq([ask_for_help, contribution])
    end

    it 'contribution firsts for :ask_for_help' do
      allow(user).to receive(:goal) { :ask_for_help }

      actions = HomeServices::Action.new(user: user, latitude: 1.122, longitude: 2.345).find_all

      expect(actions).to eq([contribution, ask_for_help])
    end
  end
end