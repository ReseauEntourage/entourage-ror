require 'rails_helper'

describe UserServices::DeleteUserService do
  let(:user) { create(:public_user, phone: '+33612345678', email: 'foo@bar.com') }

  subject { described_class.new(user: user).delete }

  context 'validated user' do
    before { subject }

    it { expect(user.reload.deleted).to eq(true) }
    it { expect(user.validation_status).to eq('deleted') }
    it { expect(user.phone).to match(/\A\+33612345678-\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/) }
    it { expect(user.email).to match(/\Afoo@bar.com-\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/) }
  end

  context 'blocked user' do
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    before do
      user.block! moderator, 'reason'
      subject
    end

    it 'is deleted but stays blocked' do
      expect(user.reload.deleted).to eq(true)
      expect(user.validation_status).to eq('blocked')
    end

    it { expect(user.phone).to match(/\A\+33612345678-\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/) }
    it { expect(User.blocked.deleted).to include(user) }
    it { expect(UserHistory.where(user_id: user.id, kind: 'deleted').count).to eq(1) }
  end

  context 'temporarily blocked user' do
    let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

    before do
      user.temporary_block! moderator, 'reason'
      subject
    end

    it 'is deleted but stays blocked' do
      expect(user.reload.deleted).to eq(true)
      expect(user.validation_status).to eq('blocked')
      expect(user.unblock_at).not_to be_nil
    end
  end
end
