module Assistant
  # The events that Local sends to the AI assistant when an account disappears, so that the
  # assistant erases what it keeps about it (its memory lasts 12 months at most otherwise).
  #
  # The assistant receives the identifier of the account (its uuid, the one that the identity route
  # returns), the nature of the event and its date: nothing else about the person.
  #
  # Two variables switch the sending on: ASSISTANT_API_URL, the URL that receives the events, and
  # ASSISTANT_SERVICE_KEY, the key of Local for them (header X-Service-Key, distinct from the key
  # that lets the assistant read Local). Without them, nothing is sent and nothing fails.
  module AccountEvents
    DELETED = 'account.deleted'.freeze
    ANONYMIZED = 'account.anonymized'.freeze
    PRODUCT = 'local'.freeze

    module_function

    def url
      ENV['ASSISTANT_API_URL'].presence
    end

    def service_key
      ENV['ASSISTANT_SERVICE_KEY'].presence
    end

    def enabled?
      url.present? && service_key.present?
    end

    # An anonymized account is anonymized, any other disappearance is a deletion.
    def event_for user
      user.anonymized? ? ANONYMIZED : DELETED
    end

    def payload event:, user_uuid:, occurred_at:
      { event: event, product: PRODUCT, userId: user_uuid, occurredAt: occurred_at }
    end
  end
end
