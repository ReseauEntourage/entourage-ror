require 'rails_helper'

RSpec.describe Api::V1::BaseController, :type => :controller do
  render_views

  describe 'validate_request!' do
    before { Rails.env.stub(:test?) { false } }
    
    context "missing api key" do
      before { get :check }
      it { expect(response.status).to eq(426) }
    end

    context "invalid api key" do
      before { @request.env['X-API-Key'] = 'foobar' }
      before { get :check }
      it { expect(response.status).to eq(426) }
    end

    context "valid api key" do
      before { @request.env['X-API-Key'] = 'api_debug' }
      before { get :check }
      it { expect(response.status).to eq(200) }
    end


  end
end