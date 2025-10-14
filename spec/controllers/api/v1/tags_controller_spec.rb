require 'rails_helper'
include AuthHelper
include CommunityHelper

RSpec.describe Api::V1::TagsController, type: :controller do
  let(:result) { JSON.parse(response.body) }

  describe 'GET interests' do
    before { get :interests }
    it { expect(response.status).to eq(200) }
    it { expect(result).to have_key('interests') }
    it { expect(result['interests']).to be_a(Hash) }
    it { expect(result['interests']).to have_key('sport') }
    it { expect(result['interests']).to have_key('other') }
    it { expect(result['interests']['sport']).to eq('Sport') }
    it { expect(result['interests']['other']).to eq('Autre') }
  end
end
