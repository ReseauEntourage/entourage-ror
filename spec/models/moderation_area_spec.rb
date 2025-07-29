require 'rails_helper'
include CommunityHelper

RSpec.describe ModerationArea, type: :model do
  describe 'departement' do
    it { expect(ModerationArea.departement :hors_zone).to eq '*' }
    it { expect(ModerationArea.departement :sans_zone).to eq '_' }
    it { expect(ModerationArea.departement 'dep_75').to eq '75' }
    it { expect{ ModerationArea.departement '75' }.to raise_error(ArgumentError) }
  end
end
