require 'rails_helper'

RSpec.describe Api::V0::StatsController, :type => :controller do
  describe 'index' do
    before(:each) do
      organization = FactoryGirl.create(:organization)
      user = FactoryGirl.create(:pro_user, organization: organization)
      tours = FactoryGirl.create_list(:tour, 2, user: user)
      FactoryGirl.create_list(:encounter, 4, tour: tours.first)
    end

    it 'should returns stats' do
      get 'index'
      resp = JSON.parse(response.body)
      expect(resp).to eq({"tours"=>2, "encounters"=>4, "organizations"=>1})
    end
  end
end