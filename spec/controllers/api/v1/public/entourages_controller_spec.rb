require 'rails_helper'

describe Api::V1::EntouragesController do
  describe 'GET show' do
    context "could get entourage with uuid" do
      let!(:entourage) { FactoryGirl.create(:entourage, status: "open") }
      before { get :show, uuid: entourage.uuid }

      it { expect(response.status).to eq(200) }
    end

    context "could not get entourage with uuid" do
      before { get :show, uuid: 'toto' }

      it { expect(response.status).to eq(404) }
    end
  end
end
