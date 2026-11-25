# Tells the AI assistant that an account was deleted or anonymized (see Assistant::AccountEvents),
# with the service key of Local. Sidekiq retries until the assistant accepts the event (network, 5xx,
# 429). A 400, 401 or 403 is a mistake of configuration or of contract that no retry fixes: it is
# reported (Sentry) once and not retried. After the last retry the failure is reported too, without
# any data about the person.
class AssistantAccountEventJob
  include Sidekiq::Worker

  # Two or three weeks of retries (the Sidekiq default): the event must not be forgotten.
  sidekiq_options queue: :default, retry: 25

  class DeliveryFailed < StandardError; end

  # The answers that no retry can change: unknown field, missing or wrong key, key of another product.
  DEFINITIVE_STATUSES = [400, 401, 403].freeze

  sidekiq_retries_exhausted do |job, exception|
    Sentry.capture_message(
      'The AI assistant never accepted an account event',
      level: :error,
      extra: { event: job['args'][1], error: exception.class.name }
    )
  end

  # @param user_uuid [String] the identifier of the account, the only thing about it that is sent
  # @param event [String] Assistant::AccountEvents::DELETED or ANONYMIZED
  # @param occurred_at [String] ISO 8601
  def perform user_uuid, event, occurred_at
    return unless Assistant::AccountEvents.enabled?

    # No Sentry breadcrumb for this call: it carries the service key and the identifier of the account.
    response = Assistant::Breadcrumbs.suppressed do
      HTTParty.post(
        Assistant::AccountEvents.events_url,
        headers: { 'Content-Type' => 'application/json', 'X-Service-Key' => Assistant::AccountEvents.service_key },
        body: Assistant::AccountEvents.payload(event: event, user_uuid: user_uuid, occurred_at: occurred_at).to_json,
        timeout: 10
      )
    end

    return if response.success?

    if DEFINITIVE_STATUSES.include?(response.code)
      Sentry.capture_message('The AI assistant refused an account event', level: :error, extra: { event: event, status: response.code })
      return
    end

    # Never the body of the answer in the error: it is not ours.
    raise DeliveryFailed, "The assistant answered #{response.code}"
  end
end
