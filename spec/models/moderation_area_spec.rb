require 'rails_helper'
include CommunityHelper

RSpec.describe ModerationArea, type: :model do
  describe 'departement' do
    it { expect(ModerationArea.departement :hors_zone).to eq '*' }
    it { expect(ModerationArea.departement :sans_zone).to eq '_' }
    it { expect(ModerationArea.departement 'dep_75').to eq '75' }
    it { expect{ ModerationArea.departement '75' }.to raise_error(ArgumentError) }
  end

  describe '#referent_benevole_with_fallback' do
    let(:referent) { create :public_user }
    let(:default_referent) { create :admin_user, slack_id: ENV['SLACK_DEFAULT_REFERENT_ID'] }

    it 'returns the referent_benevole when set' do
      moderation_area = create :moderation_area, referent_benevole: referent

      expect(moderation_area.referent_benevole_with_fallback).to eq referent
    end

    it 'returns the default referent when unset' do
      default_referent
      moderation_area = create :moderation_area, referent_benevole: nil

      expect(moderation_area.referent_benevole_with_fallback).to eq default_referent
    end
  end
end
