require 'rails_helper'

RSpec.describe AssistantAccountObserver do
  let(:user) { create(:public_user, phone: '+33600000000') }
  let(:other) { create(:public_user, phone: '+33600000002') }
  let(:moderator) { create(:pro_user, phone: '+33600000001', token: 'bar') }

  before do
    [user, other].each do |person|
      AssistantAction.create!(user: person, idempotency_key: SecureRandom.uuid, action_type: 'outing.join', request_digest: 'abc')
    end
  end

  def rows_of person
    AssistantAction.where(user_id: person.id).count
  end

  it 'deletes the rows when the user deletes their account' do
    UserServices::DeleteUserService.new(user: user).delete

    expect(rows_of(user)).to eq(0)
    expect(rows_of(other)).to eq(1)
  end

  it 'deletes the rows when the account is anonymized, as the back-office and the CNIL task do' do
    user.anonymize!(moderator)

    expect(rows_of(user)).to eq(0)
    expect(rows_of(other)).to eq(1)
  end

  it 'keeps the rows when something else changes on the account' do
    user.update!(first_name: 'Jeanne')

    expect(rows_of(user)).to eq(1)
  end

  it 'does not fail the deletion of the account when the purge fails' do
    allow(AssistantAction).to receive(:where).and_raise(StandardError, 'boom')
    allow(Sentry).to receive(:capture_exception)

    expect { UserServices::DeleteUserService.new(user: user).delete }.not_to raise_error

    expect(user.reload).to be_deleted
    expect(Sentry).to have_received(:capture_exception).with(an_instance_of(StandardError))
  end
end
