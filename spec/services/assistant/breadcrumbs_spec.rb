require 'rails_helper'

describe Assistant::Breadcrumbs do
  it 'is not suppressed by default, is inside the block, and is restored after it, even on error' do
    expect(described_class.suppressed?).to be(false)
    described_class.suppressed { expect(described_class.suppressed?).to be(true) }
    expect(described_class.suppressed?).to be(false)

    expect { described_class.suppressed { raise 'boom' } }.to raise_error('boom')
    expect(described_class.suppressed?).to be(false)
  end

  it 'keeps the HTTParty breadcrumb of the app, except for the calls of the assistant' do
    stub_request(:get, 'https://example.org/ping').to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    allow(Sentry).to receive(:add_breadcrumb)

    described_class.suppressed { HTTParty.get('https://example.org/ping', headers: { 'X-Service-Key' => 'secret' }) }
    expect(Sentry).not_to have_received(:add_breadcrumb)

    HTTParty.get('https://example.org/ping')
    expect(Sentry).to have_received(:add_breadcrumb).once
  end
end
