require 'rails_helper'

RSpec.describe Api::V0::BaseController, :type => :controller do
  render_views

  describe 'validate_request!' do
    before { Rails.env.stub(:test?) { false } }

    #TODO: active request validation when mobile apps have implemented api_key
    context "missing api key" do
      before { get :ping }
      it { expect(response.status).to eq(200) }
    end

    #TODO: active request validation when mobile apps have implemented api_key
    context "invalid api key" do
      before { @request.env['X-API-Key'] = 'foobar' }
      before { get :ping }
      it { expect(response.status).to eq(200) }
    end

    context "valid api key" do
      before { @request.env['X-API-Key'] = 'api_debug' }
      before { get :ping }
      it { expect(response.status).to eq(200) }
    end
  end
end