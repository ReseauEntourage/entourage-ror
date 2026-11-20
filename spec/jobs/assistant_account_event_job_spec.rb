require 'rails_helper'

RSpec.describe AssistantAccountEventJob do
  let(:url) { 'https://assistant.example.org/events' }
  let(:uuid) { '3f2b8c1e-0000-4000-8000-000000000001' }
  let(:occurred_at) { '2026-11-20T10:00:00Z' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return(url)
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('local-service-key')
    allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-read-key')
  end

  def perform(event = 'account.deleted')
    described_class.new.perform(uuid, event, occurred_at)
  end

  it 'posts the event with the service key of Local, and the key of the reads is not used' do
    stub = stub_request(:post, url).with(headers: { 'X-Service-Key' => 'local-service-key', 'Content-Type' => 'application/json' }).to_return(status: 200)

    perform

    expect(stub).to have_been_requested.once
    expect(a_request(:post, url).with { |request| request.headers['X-Api-Key'].nil? }).to have_been_made
  end

  it 'sends exactly the event, the product, the identifier of the account and the date: nothing else about the person' do
    stub_request(:post, url).to_return(status: 202)

    perform

    expect(a_request(:post, url).with { |request|
      JSON.parse(request.body) == { 'event' => 'account.deleted', 'product' => 'local', 'userId' => uuid, 'occurredAt' => occurred_at }
    }).to have_been_made.once
  end

  it 'tells the nature of the event: deleted or anonymized' do
    stub_request(:post, url).to_return(status: 200)

    perform('account.anonymized')

    expect(a_request(:post, url).with { |request| JSON.parse(request.body)['event'] == 'account.anonymized' }).to have_been_made.once
  end

  it 'raises when the assistant does not accept the event, so that Sidekiq retries it, and keeps its answer out of the error' do
    stub_request(:post, url).to_return(status: 503, body: 'something about a person')

    expect { perform }.to raise_error(described_class::DeliveryFailed) { |error|
      expect(error.message).to eq('The assistant answered 503')
    }
  end

  it 'raises when the assistant cannot be reached, so that Sidekiq retries it' do
    stub_request(:post, url).to_timeout

    expect { perform }.to raise_error(StandardError)
  end

  it 'is retried by Sidekiq for weeks, on the default queue' do
    expect(described_class.get_sidekiq_options).to include('retry' => 25, 'queue' => :default)
  end

  it 'is retried until it succeeds: a failure and then a success sends the event once accepted' do
    stub_request(:post, url).to_return({ status: 500 }, { status: 200 })

    expect { perform }.to raise_error(described_class::DeliveryFailed)
    expect { perform }.not_to raise_error
    expect(a_request(:post, url)).to have_been_made.twice
  end

  it 'gives up cleanly after the last retry: reported without any data about the person' do
    allow(Sentry).to receive(:capture_message)
    job = { 'class' => described_class.name, 'args' => [uuid, 'account.deleted', occurred_at] }

    described_class.sidekiq_retries_exhausted_block.call(job, described_class::DeliveryFailed.new('The assistant answered 500'))

    expect(Sentry).to have_received(:capture_message).with(
      'The AI assistant never accepted an account event',
      level: :error,
      extra: { event: 'account.deleted', error: 'AssistantAccountEventJob::DeliveryFailed' }
    )
  end

  context 'when a variable is missing' do
    it 'sends nothing and does not fail without ASSISTANT_API_URL' do
      allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return(nil)

      expect { perform }.not_to raise_error
      expect(a_request(:any, /.*/)).not_to have_been_made
    end

    it 'sends nothing and does not fail without ASSISTANT_SERVICE_KEY, or with an empty one' do
      [nil, ''].each do |value|
        allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return(value)

        expect { perform }.not_to raise_error
      end
      expect(a_request(:any, url)).not_to have_been_made
    end
  end
end
