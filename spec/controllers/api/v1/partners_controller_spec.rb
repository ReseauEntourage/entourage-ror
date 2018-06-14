require 'rails_helper'

RSpec.describe Api::V1::PartnersController, type: :controller do

  let!(:user) { FactoryGirl.create :pro_user }

  describe 'GET index' do
    let!(:partner1) { FactoryGirl.create(:partner) }
    let!(:partner2) { FactoryGirl.create(:partner) }
    before { FactoryGirl.create(:user_partner, user: user, partner: partner1) }

    before { get 'index', token: user.token }
    it { expect(JSON.parse(response.body)).to eq({"partners"=>[
                                                    {
                                                        "id"=>partner1.id,
                                                        "name"=>"MyString",
                                                        "large_logo_url"=>"MyString",
                                                        "small_logo_url"=>"MyString",
                                                        "description"=>"MyDescription",
                                                        "phone"=>nil,
                                                        "address"=>nil,
                                                        "website_url"=>nil,
                                                        "email"=>nil,
                                                        "default"=>true
                                                    },
                                                    {
                                                        "id"=>partner2.id,
                                                        "name"=>"MyString",
                                                        "large_logo_url"=>"MyString",
                                                        "small_logo_url"=>"MyString",
                                                        "description"=>"MyDescription",
                                                        "phone"=>nil,
                                                        "address"=>nil,
                                                        "website_url"=>nil,
                                                        "email"=>nil,
                                                        "default"=>false
                                                    }]}
                                              ) }
  end
end