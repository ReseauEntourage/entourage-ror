require 'rails_helper'

describe UserServices::RestoreBlockedStatus do
  let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'mod') }

  def history(user, kind, at: Time.current)
    UserHistory.create!(user_id: user.id, updater_id: moderator.id, kind: kind, metadata: {}, created_at: at)
  end

  def deleted_user(phone)
    create(:public_user, phone: phone).tap { |u| UserServices::DeleteUserService.new(user: u).delete }
  end

  # a block that was recorded but lost: the account was already deleted, the status stayed 'deleted'
  let!(:lost_block) { deleted_user('+33611111111').tap { |u| history(u, 'block') } }
  let!(:lost_block_after_unblock) do
    deleted_user('+33622222222').tap do |u|
      history(u, 'block', at: 3.days.ago)
      history(u, 'unblock', at: 2.days.ago)
      history(u, 'block', at: 1.day.ago)
    end
  end
  let!(:unblocked) do
    deleted_user('+33633333333').tap do |u|
      history(u, 'block', at: 2.days.ago)
      history(u, 'unblock', at: 1.day.ago)
    end
  end
  let!(:never_blocked) { deleted_user('+33644444444') }
  let!(:live_blocked) { create(:public_user, phone: '+33655555555').tap { |u| u.block! moderator, 'reason' } }
  let!(:live_validated) { create(:public_user, phone: '+33666666666').tap { |u| history(u, 'block', at: 2.days.ago) } }

  it 'lists only deleted accounts whose last block was lost' do
    expect(described_class.run!).to match_array([lost_block.id, lost_block_after_unblock.id])
  end

  it 'writes nothing by default' do
    described_class.run!

    expect(lost_block.reload.validation_status).to eq('deleted')
  end

  context 'writing' do
    before { described_class.run!(dry_run: false) }

    it { expect(lost_block.reload.validation_status).to eq('blocked') }
    it { expect(lost_block_after_unblock.reload.validation_status).to eq('blocked') }
    it { expect(lost_block.reload.deleted).to eq(true) }
    it { expect(unblocked.reload.validation_status).to eq('deleted') }
    it { expect(never_blocked.reload.validation_status).to eq('deleted') }
    it { expect(live_blocked.reload.validation_status).to eq('blocked') }
    it { expect(live_validated.reload.validation_status).to eq('validated') }

    it 'is idempotent' do
      expect(described_class.run!(dry_run: false)).to eq([])
    end

    it 'makes the phone number refused at signup' do
      expect(User.blocked_with_phone('+33611111111')).to eq([lost_block])
    end
  end

  it 'honors the limit' do
    expect(described_class.run!(dry_run: false, limit: 1)).to eq([lost_block.id])
    expect(lost_block_after_unblock.reload.validation_status).to eq('deleted')
  end
end
