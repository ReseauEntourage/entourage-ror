require 'rails_helper'

RSpec.describe Api::V0::StatsController, :type => :controller, skip: true do
  describe 'index' do
    before(:each) do
      organization = FactoryBot.create(:organization)
      user = FactoryBot.create(:pro_user, organization: organization)
      tours = FactoryBot.create_list(:tour, 2, user: user)
      FactoryBot.create_list(:encounter, 4, tour: tours.first)
    end

    it 'should returns stats' do
      get 'index'
      resp = JSON.parse(response.body)
      expect(resp).to eq({"tours"=>2, "encounters"=>4, "organizations"=>1})
    end
  end
end
