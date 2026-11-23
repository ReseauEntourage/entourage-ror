require 'rails_helper'

describe Assistant::Measures do
  let(:base_url) { 'https://assistant.example.org' }
  let(:url) { "#{base_url}/api/v1/measures" }
  let(:subject_id) { 'abc123DEF456' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return(base_url)
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('local-service-key')
  end

  def answer(body = nil, status: 200, **rest)
    body ||= rest
    stub_request(:get, url).with(query: { product: 'local', subject: subject_id }, headers: { 'X-Service-Key' => 'local-service-key' })
      .to_return(status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'reads the distribution of each measure of the event with the service key of Local' do
    stub = answer(
      subject: subject_id,
      metrics: {
        fears: { status: 'ok', total: 12, distribution: [{ value: 'alone', count: 7 }, { value: 'nothing', count: 5 }] },
        fit: { status: 'ok', total: 11, distribution: [{ value: 'yes', count: 11 }] },
        feeling: { status: 'too_few_responses' }
      }
    )

    metrics = described_class.for_subject(subject_id)

    expect(stub).to have_been_requested.once
    expect(metrics['fears']).to have_attributes(status: 'ok', total: 12, distribution: [{ value: 'alone', count: 7 }, { value: 'nothing', count: 5 }])
    expect(metrics['fears']).to be_ok
    expect(metrics['fit'].total).to eq(11)
    expect(metrics['feeling']).to be_too_few
  end

  it 'keeps nothing but the indication when there are too few responses, whatever the answer carries' do
    answer(subject: subject_id, metrics: { fears: { status: 'too_few_responses', total: 3, distribution: [{ value: 'alone', count: 3 }] } })

    metric = described_class.for_subject(subject_id)['fears']

    expect(metric).to have_attributes(status: 'too_few_responses', total: nil, distribution: nil)
  end

  it 'ignores what is not a known measure' do
    answer(subject: subject_id, metrics: { fears: { status: 'too_few_responses' }, secrets: { status: 'ok', total: 1, distribution: [] } })

    expect(described_class.for_subject(subject_id).keys).to eq(['fears'])
  end

  it 'is unavailable when the assistant refuses, fails, does not answer, or answers something else' do
    answer({ error: 'no' }, status: 403)
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    answer({ metrics: 'nonsense' })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    answer({ subject: subject_id, metrics: { fears: { status: 'weird' } } })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    answer({ subject: subject_id, metrics: { fears: { status: 'ok', total: 'not-a-number', distribution: 'bad' } } })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    answer({ subject: subject_id, metrics: { fears: { status: 'ok', total: 3, distribution: [{ value: 'a' }] } } })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    stub_request(:get, url).with(query: hash_including(product: 'local')).to_timeout
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)
  end

  it 'is unavailable when the answer is about another subject, or about none' do
    answer(subject: 'another000000', metrics: { fears: { status: 'ok', total: 1, distribution: [{ value: 'a', count: 1 }] } })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)

    answer(metrics: { fears: { status: 'ok', total: 1, distribution: [{ value: 'a', count: 1 }] } })
    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)
  end

  it 'is unavailable, without any request, when the assistant is not configured' do
    allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return(nil)

    expect { described_class.for_subject(subject_id) }.to raise_error(described_class::Unavailable)
    expect(a_request(:any, /assistant\.example\.org/)).not_to have_been_made
  end
end
