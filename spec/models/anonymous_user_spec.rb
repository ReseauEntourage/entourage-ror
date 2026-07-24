require 'rails_helper'

describe AnonymousUser do
  let(:user) { AnonymousUser.new(uuid: SecureRandom.uuid, community: :entourage) }

  describe 'denormalized stats counters' do
    it { expect(user.entourages_count).to eq(0) }
    it { expect(user.actions_count).to eq(0) }
    it { expect(user.outings_count).to eq(0) }
    it { expect(user.neighborhoods_count).to eq(0) }
  end
end
