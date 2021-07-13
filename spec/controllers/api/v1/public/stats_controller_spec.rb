require 'rails_helper'

describe Api::V1::Public::StatsController do
  describe 'index' do
    before(:each) do
      test_organization = FactoryBot.create(:organization, test_organization: true)
      test_user = FactoryBot.create(:pro_user, organization: test_organization)
      test_tours = FactoryBot.create_list(:tour, 2, user: test_user)
      FactoryBot.create_list(:encounter, 4, tour: test_tours.first)

      organization = FactoryBot.create(:organization)
      user = FactoryBot.create(:pro_user, organization: organization)
      tours = FactoryBot.create_list(:tour, 2, user: user)
      FactoryBot.create_list(:encounter, 4, tour: tours.first)

      # actions
      create :entourage, display_category: nil
      create :entourage, display_category: :social

      # excluded action
      create :entourage, status: :blacklisted

      # events
      create :outing

      # excluded event
      create :outing, community: :pfp
    end

    it 'should returns stats' do
      get 'index'
      resp = JSON.parse(response.body)
      expect(resp).to eq({
        'tours'=>2,
        'encounters'=>4,
        'organizations'=>1,
        'actions'=>2,
        'events'=>1,
        'users'=>6
      })
    end
  end
end
