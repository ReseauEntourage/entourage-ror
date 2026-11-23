require 'rails_helper'

describe Assistant::ActionRunner do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:public_user) }
  let(:key) { SecureRandom.uuid }
  let(:payload) { { outing_id: 12, text: 'Bonjour, première fois !' } }
  let(:executions) { [] }

  def runner(key: self.key, payload: self.payload, action_type: 'test.act', user: self.user)
    described_class.new(user: user, key: key, action_type: action_type, payload: payload)
  end

  def success(subject: nil)
    described_class::Outcome.new(status: 201, body: { id: 7, status: 'done' }, subject: subject)
  end

  describe 'a first request' do
    it 'runs the action, stores the key with its result and its subject, and answers it' do
      outing = create(:outing)

      response = runner.call { executions << 1; success(subject: outing) }

      expect(response).to have_attributes(status: 201, body: { id: 7, status: 'done' }, result: 'succeeded', replayed: false)
      expect(executions.size).to eq(1)
      row = AssistantAction.find_by!(user_id: user.id, idempotency_key: key)
      expect(row).to have_attributes(action_type: 'test.act', status: 'succeeded', subject: outing)
      expect(row.result).to eq('http_status' => 201, 'body' => { 'id' => 7, 'status' => 'done' })
    end

    it 'never stores the content of the request, only a keyed digest of it' do
      runner.call { success }

      row = AssistantAction.last
      expect(row.attributes.values.join(' ')).not_to include('première fois')
      expect(row.request_digest).to match(/\A\h{64}\z/)
    end
  end

  describe 'a replayed request' do
    it 'answers the first result without running the action again' do
      first = runner.call { executions << 1; success }
      second = runner.call { executions << 2; success }

      expect(executions).to eq([1])
      expect(second).to have_attributes(status: first.status, body: first.body.deep_stringify_keys, result: 'succeeded', replayed: true)
      expect(AssistantAction.where(user_id: user.id).count).to eq(1)
    end

    it 'is replayed whatever the order of the keys of the payload' do
      runner(payload: { a: 1, b: { c: 2, d: 3 } }).call { executions << 1; success }
      runner(payload: { b: { d: 3, c: 2 }, a: 1 }).call { executions << 2; success }

      expect(executions).to eq([1])
    end
  end

  describe 'the same key for another request' do
    it 'refuses a different content with a 422 IDEMPOTENCY_KEY_REUSED and runs nothing' do
      runner.call { executions << 1; success }
      response = runner(payload: payload.merge(text: 'Autre texte')).call { executions << 2; success }

      expect(response.status).to eq(422)
      expect(response.body.dig(:error, :code)).to eq('IDEMPOTENCY_KEY_REUSED')
      expect(executions).to eq([1])
    end

    it 'refuses a different type of action' do
      runner.call { executions << 1; success }
      response = runner(action_type: 'test.other').call { executions << 2; success }

      expect(response.status).to eq(422)
      expect(executions).to eq([1])
    end

    it 'does not mix the keys of two users' do
      other = create(:public_user)
      runner.call { executions << 1; success }
      response = runner(user: other).call { executions << 2; success }

      expect(response.status).to eq(201)
      expect(executions).to eq([1, 2])
    end
  end

  describe 'a request without a valid key' do
    [nil, '', '   ', 'a key with spaces', 'é', 'a' * 129].each do |bad_key|
      it "refuses #{bad_key.inspect} with a 400 IDEMPOTENCY_KEY_REQUIRED and runs nothing" do
        response = runner(key: bad_key).call { executions << 1; success }

        expect(response).to have_attributes(status: 400, result: 'rejected')
        expect(response.body.dig(:error, :code)).to eq('IDEMPOTENCY_KEY_REQUIRED')
        expect(executions).to be_empty
        expect(AssistantAction.count).to eq(0)
      end
    end
  end

  describe 'a request that is still being processed' do
    it 'answers 409 ACTION_IN_PROGRESS and runs nothing' do
      AssistantAction.create!(user: user, idempotency_key: key, action_type: 'test.act', request_digest: runner.send(:digest))

      response = runner.call { executions << 1; success }

      expect(response).to have_attributes(status: 409, result: 'rejected')
      expect(response.body.dig(:error, :code)).to eq('ACTION_IN_PROGRESS')
      expect(executions).to be_empty
    end
  end

  describe 'a row that stays processing' do
    def processing_row
      AssistantAction.create!(user: user, idempotency_key: key, action_type: 'test.act', request_digest: runner.send(:digest))
    end

    it 'answers 409 ACTION_IN_PROGRESS before 2 minutes' do
      processing_row

      travel(119.seconds) do
        response = runner.call { executions << 1; success }

        expect(response.status).to eq(409)
        expect(response.body.dig(:error, :code)).to eq('ACTION_IN_PROGRESS')
        expect(AssistantAction.last).to be_processing
      end
      expect(executions).to be_empty
    end

    it 'is abandoned after 2 minutes: 410 ACTION_EXPIRED, marked failed, and never run under this key' do
      processing_row

      travel(121.seconds) do
        response = runner.call { executions << 1; success }

        expect(response).to have_attributes(status: 410, result: 'failed', replayed: false)
        expect(response.body.dig(:error, :code)).to eq('ACTION_EXPIRED')
      end
      expect(AssistantAction.last).to be_failed
      expect(AssistantAction.last.result.to_json).not_to include('première fois')
      expect(executions).to be_empty
    end

    it 'answers the same 410 to every later request with the same key, which stays failed' do
      processing_row

      travel(121.seconds) do
        runner.call { executions << 1; success }
        later = runner.call { executions << 2; success }

        expect(later).to have_attributes(status: 410, replayed: true)
        expect(later.body.dig('error', 'code')).to eq('ACTION_EXPIRED')
      end
      travel(1.day) { expect(runner.call { executions << 3; success }.status).to eq(410) }
      expect(executions).to be_empty
    end

    it 'runs the action of a new key, after the first one expired' do
      processing_row

      travel(121.seconds) do
        runner.call { executions << 1; success }
        fresh = runner(key: SecureRandom.uuid).call { executions << 2; success }

        expect(fresh).to have_attributes(status: 201, result: 'succeeded')
      end
      expect(executions).to eq([2])
    end

    it 'does not turn into a success an action that finishes after it expired' do
      row = processing_row

      travel(121.seconds) { runner.call { success } }
      runner.send(:finish, row, AssistantAction::SUCCEEDED, { 'http_status' => 201, 'body' => {} })

      expect(row.reload).to be_failed
    end

    it 'refuses another request with the same key before looking at the expiry' do
      processing_row

      travel(121.seconds) do
        response = runner(payload: payload.merge(text: 'Autre texte')).call { success }

        expect(response.status).to eq(422)
      end
    end
  end

  describe 'a failed action' do
    it 'stores a refusal of the app as failed and answers it, with the same answer on replay' do
      refuse = lambda do
        raise described_class::Refusal.new(status: 400, code: 'CANNOT_JOIN', message: 'Could not join', reasons: ['Full'])
      end

      first = runner.call { executions << 1; refuse.call }
      second = runner.call { executions << 2; success }

      expect(first).to have_attributes(status: 400, result: 'failed', replayed: false)
      expect(first.body).to eq(error: { code: 'CANNOT_JOIN', message: 'Could not join', reasons: ['Full'] })
      expect(second).to have_attributes(status: 400, result: 'failed', replayed: true)
      expect(second.body).to eq(first.body.deep_stringify_keys)
      expect(executions).to eq([1])
      expect(AssistantAction.last).to be_failed
    end

    it 'logs the class of an unexpected error and the type of action, never its message nor its backtrace' do
      allow(Sentry).to receive(:capture_message)
      allow(Rails.logger).to receive(:error)

      runner(action_type: 'outing.publish').call { raise ArgumentError, 'Bonjour, première fois !' }

      expect(Rails.logger).to have_received(:error).once.with('Assistant action failed: outing.publish (ArgumentError)')
    end

    it 'stores an unexpected error as failed, reports it, and never leaks its message' do
      allow(Sentry).to receive(:capture_message)

      response = runner.call { executions << 1; raise StandardError, 'Bonjour, première fois !' }
      replay = runner.call { executions << 2; success }

      expect(response).to have_attributes(status: 500, result: 'failed')
      expect(response.body.dig(:error, :code)).to eq('ACTION_FAILED')
      expect(response.body.to_json).not_to include('première fois')
      expect(replay).to have_attributes(status: 500, replayed: true)
      expect(executions).to eq([1])
      expect(Sentry).to have_received(:capture_message).once
    end
  end

  # Two requests with the same key at the same time: the unique index decides, the action is run
  # once. It needs real commits and two connections, so it does not run in the transaction of the spec.
  describe 'two simultaneous requests' do
    self.use_transactional_tests = false

    let!(:racing_user) { create(:public_user, phone: '+33699999911') }

    after do
      AssistantAction.where(user_id: racing_user.id).delete_all
      User.where(id: racing_user.id).delete_all
    end

    it 'runs the action once, the other request is told it is in progress' do
      started = Queue.new
      release = Queue.new
      executions = Queue.new

      first = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          runner(user: racing_user).call do
            executions << 1
            started << true
            release.pop
            success
          end
        end
      end
      started.pop # the first request holds the key, its action is running

      second = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          runner(user: racing_user).call { executions << 2; success }
        end
      end
      second_response = second.value
      release << true
      first_response = first.value

      expect(first_response).to have_attributes(status: 201, result: 'succeeded')
      expect(second_response).to have_attributes(status: 409, result: 'rejected')
      expect(executions.size).to eq(1)
      expect(AssistantAction.where(user_id: racing_user.id).count).to eq(1)
    end
  end
end
