require 'rails_helper'
include AuthHelper

describe Admin::ResourcesController do
  let!(:user) { admin_basic_login }

  context 'destroy' do
    let(:resource) { create :resource }
    let(:result) { Resource.unscoped.find(resource.id) }

    before { delete :destroy, params: { id: resource.id } }

    it { expect(response.status).to eq 302 }
    it { expect(result.status).to eq 'deleted' }
  end
end
