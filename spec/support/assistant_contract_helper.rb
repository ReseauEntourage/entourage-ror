# Helpers of the contract test between the AI assistant and Local (spec/requests/assistant/contract_spec.rb).
#
# The real answers of the controllers are written to spec/fixtures/assistant_contract/responses/<case>.json
# (status, the useful response headers, JSON body) and the spec fails when an answer changes without the
# file being regenerated: REGENERATE_CONTRACT=1 bundle exec rspec spec/requests/assistant/contract_spec.rb
#
# Nothing personal goes into a snapshot: the identifiers of the records created for the case are replaced by
# placeholders, and the dates by <time>.
module AssistantContractHelper
  CONTRACT_DIR = Rails.root.join('spec/fixtures/assistant_contract').freeze
  RESPONSES_DIR = CONTRACT_DIR.join('responses').freeze
  # The response headers that the assistant reads.
  RESPONSE_HEADERS = ['Idempotent-Replayed'].freeze
  TIME = /\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)/

  API_KEY = 'assistant-secret-key'.freeze

  def contract_headers(token:, key: nil, api_key: API_KEY)
    headers = { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    headers['X-API-KEY'] = api_key if api_key
    headers['Authorization'] = "Bearer #{token}" if token
    headers['Idempotency-Key'] = key if key
    headers
  end

  # Sends the request as the assistant does: JSON, the keys in headers only.
  def send_as_assistant(method, path, token:, body: nil, query: nil, key: nil, api_key: API_KEY)
    path = "#{path}?#{query.to_query}" if query.present?
    args = { headers: contract_headers(token: token, key: key, api_key: api_key) }
    args[:params] = body.to_json if body && method.to_s != 'get'
    public_send(method.to_s.downcase, path, **args)
  end

  # `aliases`: { real value => placeholder } for the records of the case.
  def check_snapshot name, aliases: {}
    actual = snapshot_of(response, aliases)
    file = RESPONSES_DIR.join("#{name}.json")

    if ENV['REGENERATE_CONTRACT'].present?
      FileUtils.mkdir_p(RESPONSES_DIR)
      File.write(file, "#{JSON.pretty_generate(actual)}\n")
    else
      expect(file).to exist, "no snapshot for #{name}: REGENERATE_CONTRACT=1 bundle exec rspec spec/requests/assistant/contract_spec.rb"
      expect(actual).to eq(JSON.parse(File.read(file))), "the answer of #{name} changed: regenerate the snapshot if it is wanted"
    end
  end

  # The ids of the records that the action created are different at each run: a placeholder instead.
  GENERATED_IDS = { 'messageId' => '<message-id>', 'conversationId' => '<conversation-id>' }.freeze

  def anonymize_ids value
    case value
    when Hash
      value.each_with_object({}) do |(key, inner), result|
        result[key] =
          if GENERATED_IDS.key?(key) && !inner.is_a?(Hash)
            GENERATED_IDS[key]
          elsif key == 'id' && inner.is_a?(String) && inner.match?(/\A[A-Za-z0-9_-]{12}\z/)
            '<id>'
          else
            anonymize_ids(inner)
          end
      end
    when Array then value.map { |inner| anonymize_ids(inner) }
    else value
    end
  end

  def snapshot_of response, aliases
    body = response.body.to_s
    aliases.sort_by { |value, _| -value.to_s.length }.each { |value, placeholder| body = body.gsub(value.to_s, placeholder) }
    body = body.gsub(TIME, '<time>')
    parsed = body.empty? ? nil : anonymize_ids(JSON.parse(body))

    {
      'status' => response.status,
      'headers' => RESPONSE_HEADERS.each_with_object({}) { |name, kept| kept[name] = response.headers[name] if response.headers[name] },
      'body' => parsed
    }
  end
end

RSpec.configure { |config| config.include AssistantContractHelper, type: :request }
