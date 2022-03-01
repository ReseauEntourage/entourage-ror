require 'rails_helper'

describe HomeServices::Action do
  let(:user) { FactoryBot.create(:pro_user_paris) }
  let!(:ask_for_help) { FactoryBot.create(:entourage, entourage_type: :ask_for_help, title: 'ask_for_help') }
  let!(:contribution) { FactoryBot.create(:entourage, entourage_type: :contribution, title: 'contribution') }
  let!(:pin) { FactoryBot.create(:entourage, pin: true, pins: '75', title: 'pin') }

  describe 'find_all' do
    let(:subject) { HomeServices::Action.new(user: user, latitude: 1.122, longitude: 2.345) }

    it 'ask_for_help firsts for :offer_help' do
      allow(user).to receive(:goal) { :offer_help }

      actions = subject.find_all

      expect(actions).to eq([ask_for_help, contribution])
    end

    it 'contribution firsts for :ask_for_help' do
      allow(user).to receive(:goal) { :ask_for_help }

      actions = subject.find_all

      expect(actions).to eq([contribution, ask_for_help])
    end

    it 'no ask_for_help if entourage_type is contribution' do
      actions = subject.find_all(entourage_type: :contribution)

      expect(actions).to eq([contribution])
    end

    it 'no contribution if entourage_type is ask_for_help' do
      actions = subject.find_all(entourage_type: :ask_for_help)

      expect(actions).to eq([ask_for_help])
    end
  end
end
