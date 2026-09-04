require 'rails_helper'
include AuthHelper

describe Admin::OutingsController do
  describe 'GET index rendering (regression: missing partial / template errors)' do
    render_views

    let!(:admin) { admin_basic_login }
    let!(:outing) { FactoryBot.create(:outing) }

    it 'renders index' do
      get :index
      expect(response).to be_successful
    end

    it 'renders index with a search filter' do
      get :index, params: { search: outing.title }
      expect(response).to be_successful
    end
  end
end
