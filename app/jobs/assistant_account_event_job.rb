# Tells the AI assistant that an account was deleted or anonymized (see Assistant::AccountEvents),
# with the service key of Local. Sidekiq retries until the assistant accepts the event; after the
# last retry the failure is reported (Sentry) without any data about the person.
class AssistantAccountEventJob
  include Sidekiq::Worker

  # Two or three weeks of retries (the Sidekiq default): the event must not be forgotten.
  sidekiq_options queue: :default, retry: 25

  class DeliveryFailed < StandardError; end

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

    response = HTTParty.post(
      Assistant::AccountEvents.url,
      headers: { 'Content-Type' => 'application/json', 'X-Service-Key' => Assistant::AccountEvents.service_key },
      body: Assistant::AccountEvents.payload(event: event, user_uuid: user_uuid, occurred_at: occurred_at).to_json,
      timeout: 10
    )

    # Never the body of the answer in the error: it is not ours.
    raise DeliveryFailed, "The assistant answered #{response.code}" unless response.success?
  end
end
