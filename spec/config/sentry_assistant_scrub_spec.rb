require 'rails_helper'

# The routes of the AI assistant carry texts of the people and the secrets of the assistant:
# Sentry (send_default_pii is on) must not receive them.
describe 'Sentry before_send' do
  def event_for(path)
    env = Rack::MockRequest.env_for(
      "https://api.example.org#{path}?q=secret+words",
      method: 'POST',
      input: { text: 'A very private sentence' }.to_json,
      'CONTENT_TYPE' => 'application/json',
      'HTTP_AUTHORIZATION' => 'Bearer user-secret-token',
      'HTTP_X_API_KEY' => 'assistant-secret-key',
      'HTTP_IDEMPOTENCY_KEY' => 'a-key'
    )
    configuration = Sentry::Configuration.new.tap { |c| c.send_default_pii = true }
    Sentry::Event.new(configuration: configuration).tap { |event| event.rack_env = env }
  end

  def scrubbed(path)
    Sentry.configuration.before_send.call(event_for(path), {}).to_hash.to_json
  end

  it 'removes the texts and the secrets from an event raised on an assistant route' do
    json = scrubbed('/api/v1/assistant/outings/42/join')

    expect(json).to include('/api/v1/assistant/outings/42/join')
    ['very private', 'secret words', 'user-secret-token', 'assistant-secret-key', 'a-key'].each do |secret|
      expect(json).not_to include(secret)
    end
  end

  it 'leaves the events of the other routes as they were' do
    json = scrubbed('/api/v1/users/me')

    expect(json).to include('user-secret-token').or include('very private')
  end
end
