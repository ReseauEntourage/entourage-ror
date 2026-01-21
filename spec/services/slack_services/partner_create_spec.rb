require 'rails_helper'

describe SlackServices::PartnerCreate do
  let(:user) { create(:public_user) }
  let(:partner) { create(:partner, users: [user]) }
  let(:partner_create) { described_class.new(partner: partner) }

  describe 'payload' do
    let(:subject) { partner_create.payload }

    it { expect(subject).to have_key(:blocks) }
  end
end
