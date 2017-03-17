require 'rails_helper'

describe Api::V1::Public::EntouragesController do
  describe 'GET show' do
    context "could get entourage with uuid" do
      let!(:entourage) { FactoryGirl.create(:entourage, status: "open") }

      before do
        stub_request(:get,  /http:\/\/maps.googleapis.com\/maps\/api\/geocode/)
          .to_return(:status => 200, :body => "", :headers => {})
        get :show, uuid: entourage.uuid
      end

      it { expect(response.status).to eq(200) }
    end

    context "could not get entourage with uuid" do
      before { get :show, uuid: 'toto' }

      it { expect(response.status).to eq(404) }
    end
  end
end
