require 'rails_helper'

describe Api::V1::Public::StatsController do
  describe 'index' do
    before(:each) do
      test_organization = FactoryGirl.create(:organization, test_organization: true)
      test_user = FactoryGirl.create(:pro_user, organization: test_organization)
      test_tours = FactoryGirl.create_list(:tour, 2, user: test_user)
      FactoryGirl.create_list(:encounter, 4, tour: test_tours.first)

      organization = FactoryGirl.create(:organization)
      user = FactoryGirl.create(:pro_user, organization: organization)
      tours = FactoryGirl.create_list(:tour, 2, user: user)
      FactoryGirl.create_list(:encounter, 4, tour: tours.first)
    end

    it 'should returns stats' do
      get 'index'
      resp = JSON.parse(response.body)
      expect(resp).to eq({'tours'=>2, 'encounters'=>4, 'organizations'=>1})
    end
  end
end
