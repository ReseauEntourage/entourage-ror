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

  it 'deletes the rows when an account that was already deleted is anonymized afterwards' do
    UserServices::DeleteUserService.new(user: user).delete
    AssistantAction.create!(user: user, idempotency_key: SecureRandom.uuid, action_type: 'outing.join', request_digest: 'abc')

    user.reload.anonymize!(moderator)

    expect(rows_of(user)).to eq(0)
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

  describe 'the event sent to the assistant' do
    let(:url) { 'https://assistant.example.org' }
    let(:enabled) { true }

    around { |example| Sidekiq::Testing.fake! { example.run } }

    before do
      Sidekiq::Worker.clear_all
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return(enabled ? url : nil)
      allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return(enabled ? 'local-service-key' : nil)
    end

    def queued
      AssistantAccountEventJob.jobs.map { |job| job['args'].values_at(0, 1) }
    end

    it 'queues the event when the user deletes their account in the app' do
      UserServices::DeleteUserService.new(user: user).delete

      expect(queued).to eq([[user.uuid, 'account.deleted']])
      expect(AssistantAccountEventJob.jobs.first['args'][2]).to match(/\A\d{4}-\d\d-\d\dT/)
    end

    # The CNIL task (CnilAnonymize) goes through the same User#anonymize!, but it calls it without the
    # `updater` argument that the method requires, so it fails today (EN-9878, design.md, spike 1.4).
    it 'queues the event when the back-office anonymizes the account' do
      user.anonymize!(moderator)

      expect(queued).to eq([[user.uuid, 'account.anonymized']])
    end

    it 'queues nothing when something else changes on the account, nor when the account is restored' do
      user.update!(first_name: 'Jeanne')
      UserServices::DeleteUserService.new(user: user).delete
      Sidekiq::Worker.clear_all
      UserServices::DeleteUserService.new(user: user).undelete

      expect(queued).to eq([])
    end

    it 'queues the event once per deletion' do
      UserServices::DeleteUserService.new(user: user).delete
      user.first_name = 'Jeanne'
      user.save(validate: false)

      expect(queued.size).to eq(1)
    end

    it 'does not fail the deletion of the account when the job cannot be queued, and reports it' do
      allow(AssistantAccountEventJob).to receive(:perform_async).and_raise(Redis::CannotConnectError, 'boom')
      allow(Sentry).to receive(:capture_exception)

      expect { UserServices::DeleteUserService.new(user: user).delete }.not_to raise_error

      expect(user.reload).to be_deleted
      expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Redis::CannotConnectError))
    end

    it 'still purges the rows of the account when the job cannot be queued' do
      allow(AssistantAccountEventJob).to receive(:perform_async).and_raise(StandardError, 'boom')
      allow(Sentry).to receive(:capture_exception)

      UserServices::DeleteUserService.new(user: user).delete

      expect(rows_of(user)).to eq(0)
    end

    context 'without the variables of the assistant' do
      let(:enabled) { false }

      it 'queues nothing and does not fail' do
        expect { UserServices::DeleteUserService.new(user: user).delete }.not_to raise_error

        expect(queued).to eq([])
        expect(user.reload).to be_deleted
      end
    end
  end
end
