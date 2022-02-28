require 'rails_helper'
include AuthHelper
include CommunityHelper

RSpec.describe Api::V1::TagsController, :type => :controller do
  let(:result) { JSON.parse(response.body) }

  describe 'GET interests' do
    before { get :interests }
    it { expect(response.status).to eq(200) }
    it { expect(result).to eq({ "interests" => ["culture", "jardinage", "jeux", "sport"] }) }
  end
end
