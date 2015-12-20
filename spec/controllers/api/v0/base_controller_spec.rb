require 'rails_helper'

describe Api::V0::BaseController do

  describe 'validate_request!' do
    before { Rails.env.stub(:test?) { false } }

    context "missing api key" do
      before { get :ping }
      it { expect(response.status).to eq(426) }
    end

    context "invalid api key" do
      before { @request.env['X-API-Key'] = 'foobar' }
      before { get :ping }
      it { expect(response.status).to eq(426) }
    end

    context "valid api key" do
      before { @request.env['X-API-Key'] = 'api_debug' }
      before { get :ping }
      it { expect(response.status).to eq(426) }
    end
  end
end