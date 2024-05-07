require 'rails_helper'

describe Actionable do
  let(:solicitation) { create :solicitation }

  # verify async method is reachable
  describe 'async' do
    after { solicitation }

    it { expect(FollowingService).to receive(:on_create_entourage) }
  end
end
