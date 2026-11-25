module Assistant
  # The anonymous measures of an event (fears at the registration, feeling of being in the right place,
  # feeling after a meeting), kept by the assistant and read by Local to show them to the team.
  #
  # Local keeps no individual answer and receives none: only the aggregate of a subject, with the
  # minimal threshold applied by the assistant. Below it the assistant answers `too_few_responses`
  # and nothing else: nothing else is shown, whatever else the answer would carry.
  #
  #   GET <ASSISTANT_API_URL>/api/v1/measures?product=local&subject=<id of the event>
  #   X-Service-Key: <ASSISTANT_SERVICE_KEY>  (the key of Local, not the one of the reads)
  class Measures
    METRICS = %w[fears fit feeling].freeze
    TOO_FEW = 'too_few_responses'.freeze

    # One measure: `ok` with its total and its distribution, or `too_few_responses` alone.
    Metric = Struct.new(:status, :total, :distribution, keyword_init: true) do
      def ok?
        status == 'ok'
      end

      def too_few?
        status == TOO_FEW
      end
    end

    class Unavailable < StandardError; end

    # @return [Hash{String => Metric}] the metrics of the subject, by name
    # @raise [Unavailable] when the assistant is not configured, does not answer, or answers something
    #   that is not the contract
    def self.for_subject subject
      raise Unavailable, 'not configured' unless AccountEvents.enabled?

      response = Breadcrumbs.suppressed do
        HTTParty.get(
          "#{AccountEvents.url}/api/v1/measures",
          query: { product: AccountEvents::PRODUCT, subject: subject },
          headers: { 'X-Service-Key' => AccountEvents.service_key }, timeout: 5
        )
      end
      raise Unavailable, "status #{response.code}" unless response.success?

      body = response.parsed_response
      # An aggregate of another subject (cache, routing) is never shown under this one.
      raise Unavailable, 'unexpected subject' unless body.is_a?(Hash) && body['subject'].to_s == subject.to_s

      parse(body)
    rescue HTTParty::Error, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
      raise Unavailable, e.class.name
    end

    def self.parse body
      metrics = body.is_a?(Hash) ? body['metrics'] : nil
      raise Unavailable, 'unexpected answer' unless metrics.is_a?(Hash)

      METRICS.each_with_object({}) do |name, parsed|
        metric = metrics[name]
        # Every known measure must be there: a missing one is not "too few responses".
        raise Unavailable, 'missing metric' unless metric.is_a?(Hash)

        parsed[name] = metric_from(metric)
      end
    end

    def self.metric_from metric
      return Metric.new(status: TOO_FEW) if metric['status'] == TOO_FEW
      raise Unavailable, 'unexpected metric' unless metric['status'] == 'ok'

      entries = metric['distribution']
      valid = metric['total'].is_a?(Integer) && entries.is_a?(Array) &&
        entries.all? { |entry| entry.is_a?(Hash) && entry['value'].present? && entry['count'].is_a?(Integer) }
      raise Unavailable, 'unexpected metric' unless valid

      Metric.new(status: 'ok', total: metric['total'], distribution: entries.map { |entry| { value: entry['value'].to_s, count: entry['count'] } })
    end
  end
end
