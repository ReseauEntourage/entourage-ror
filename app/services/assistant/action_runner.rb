module Assistant
  # Runs an action that the AI assistant asks on behalf of a user, once per idempotency key.
  #
  # The key is the id of the preview that the person confirmed. The first request with a key
  # inserts a row in assistant_actions (unique on user and key) before doing anything, then runs
  # the block and stores its result. A replayed request gets the stored answer and nothing is
  # done a second time; the unique index, not a read, decides who runs when two requests race.
  #
  #   runner = Assistant::ActionRunner.new(user: user, key: key, action_type: 'outing.join',
  #                                        payload: { outing_id: outing.id })
  #   response = runner.call { Assistant::ActionRunner::Outcome.new(status: 201, body: {...}, subject: join_request) }
  #
  # The block returns an Outcome, or raises Refusal when the app would refuse the action too.
  # A failed action (refusal or error) is stored as `failed`: the same key never runs it again,
  # the assistant has to ask a new preview. A row that stays `processing` for more than
  # PROCESSING_TTL (the process died: an action takes seconds, see RACK_TIMEOUT) is dead: the
  # next request with its key marks it `failed` (ACTION_EXPIRED, 410) and never runs the action,
  # the person asks a new action with a new key. Nothing here keeps a text: `payload` is only hashed
  # and `body` must only carry identifiers and statuses.
  class ActionRunner
    KEY_FORMAT = /\A[A-Za-z0-9_.:-]{1,128}\z/
    PROCESSING_TTL = 2.minutes

    # What an action produced: HTTP status, JSON body, and the object it created or modified.
    Outcome = Struct.new(:status, :body, :subject, keyword_init: true)

    # What the controller renders. `result` is for the logs: succeeded, failed or rejected
    # (the request itself was refused before any action ran).
    Response = Struct.new(:status, :body, :result, :replayed, keyword_init: true)

    # The action is refused, as the app would refuse it. Never carries more than a code, a
    # message and the reasons of the validations.
    class Refusal < StandardError
      attr_reader :status, :code, :reasons

      def initialize(status:, code:, message:, reasons: nil)
        super(message)
        @status = status
        @code = code
        @reasons = reasons
      end
    end

    attr_reader :user, :key, :action_type

    def initialize user:, key:, action_type:, payload: {}
      @user = user
      @key = key.to_s
      @action_type = action_type
      @payload = payload
    end

    def call
      return rejected(400, 'IDEMPOTENCY_KEY_REQUIRED', 'A valid Idempotency-Key header is required.') unless KEY_FORMAT.match?(key)

      action = begin_action
      return replay(action) unless action.equal?(@started)

      execute(action) { yield }
    end

    private

    def begin_action
      @started = AssistantAction.new(
        user: user, idempotency_key: key, action_type: action_type,
        request_digest: digest, status: AssistantAction::PROCESSING
      )
      @started.save!(validate: false)
      @started
    rescue ActiveRecord::RecordNotUnique
      AssistantAction.find_by!(user_id: user.id, idempotency_key: key)
    end

    def execute action
      outcome = yield
      finish(action, AssistantAction::SUCCEEDED, stored(outcome.status, outcome.body), outcome.subject)
      Response.new(status: outcome.status, body: outcome.body, result: 'succeeded', replayed: false)
    rescue Refusal => e
      refused = error_body(e.code, e.message, e.reasons)
      finish(action, AssistantAction::FAILED, stored(e.status, refused))
      Response.new(status: e.status, body: refused, result: 'failed', replayed: false)
    rescue StandardError => e
      # Never the message of the error in the answer: it could carry a text of the user.
      Sentry.capture_exception(e)
      failure = error_body('ACTION_FAILED', 'The action could not be run.')
      finish(action, AssistantAction::FAILED, stored(500, failure))
      Response.new(status: 500, body: failure, result: 'failed', replayed: false)
    end

    # Ends a row that is still `processing`, and only that one: a row that expired meanwhile stays
    # `failed`, the action is not recorded as done after the person was told it expired.
    def finish action, status, result, subject = nil
      AssistantAction.where(id: action.id, status: AssistantAction::PROCESSING).update_all(
        status: status, result: result, subject_type: subject&.class&.base_class&.name, subject_id: subject&.id, updated_at: Time.current
      )
    end

    def replay action
      if action.request_digest != digest
        return rejected(422, 'IDEMPOTENCY_KEY_REUSED', 'This Idempotency-Key was used for another request.')
      end

      if action.processing?
        return rejected(409, 'ACTION_IN_PROGRESS', 'This action is already being processed.') unless expired?(action)

        return replay(action.reload) unless expire(action)

        return expired_response
      end

      Response.new(
        status: action.result['http_status'], body: action.result['body'],
        result: action.status, replayed: true
      )
    end

    def expired? action
      action.updated_at < PROCESSING_TTL.ago
    end

    # @return [Boolean] whether this call ended the row (false: it finished meanwhile)
    def expire action
      AssistantAction.where(id: action.id, status: AssistantAction::PROCESSING).update_all(
        status: AssistantAction::FAILED, result: stored(410, expired_body), updated_at: Time.current
      ) == 1
    end

    def expired_body
      error_body('ACTION_EXPIRED', 'This action took too long and was abandoned: ask for a new one.')
    end

    def expired_response
      Response.new(status: 410, body: expired_body, result: 'failed', replayed: false)
    end

    def rejected status, code, message
      Response.new(status: status, body: error_body(code, message), result: 'rejected', replayed: false)
    end

    def error_body code, message, reasons = nil
      error = { code: code, message: message }
      error[:reasons] = reasons if reasons.present?
      { error: error }
    end

    def stored status, body
      { 'http_status' => status, 'body' => body.deep_stringify_keys }
    end

    # Keyed digest of the request: a short text can not be guessed from it.
    def digest
      @digest ||= OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, canonical([action_type, @payload]).to_json)
    end

    def canonical value
      case value
      when Hash then value.map { |k, v| [k.to_s, canonical(v)] }.sort_by(&:first)
      when Array then value.map { |v| canonical(v) }
      else value
      end
    end
  end
end
