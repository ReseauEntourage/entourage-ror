require 'rails_helper'

# The throttles are only declared in production: the file is loaded again here, with the
# production flag, to check what each throttle counts.
describe 'Rack::Attack throttles' do
  def request_for(path, ip: '203.0.113.9')
    Rack::Attack::Request.new(Rack::MockRequest.env_for(path, 'REMOTE_ADDR' => ip))
  end

  def counted_by(throttle_name, path)
    Rack::Attack.throttles.fetch(throttle_name).block.call(request_for(path))
  end

  def load_initializer
    allow(EnvironmentHelper).to receive(:production?).and_return(true)
    Rack::Attack.clear_configuration
    load Rails.root.join('config/initializers/rack_attack.rb')
  end

  after do
    ENV.delete('ASSISTANT_THROTTLE_LIMIT')
    Rack::Attack.clear_configuration
  end

  before { load_initializer }

  it 'keeps counting the other routes by IP address in req/ip, and not in the assistant limit' do
    expect(counted_by('req/ip', '/api/v1/users/me')).to eq '203.0.113.9'
    expect(counted_by('assistant/ip', '/api/v1/users/me')).to be_nil
    expect(Rack::Attack.throttles.fetch('req/ip').limit).to eq 600
  end

  it 'takes the routes of the assistant out of req/ip and counts them in their own limit' do
    expect(counted_by('req/ip', '/api/v1/assistant/identity')).to be_nil
    expect(counted_by('assistant/ip', '/api/v1/assistant/identity')).to eq '203.0.113.9'
  end

  it 'does not take a look-alike path out of req/ip' do
    expect(counted_by('req/ip', '/api/v1/assistants')).to eq '203.0.113.9'
    expect(counted_by('assistant/ip', '/api/v1/assistants')).to be_nil
  end

  it 'gives the assistant a provisional own limit, per 5 minutes' do
    throttle = Rack::Attack.throttles.fetch('assistant/ip')

    expect(throttle.limit).to eq 3000
    expect(throttle.period).to eq 5.minutes
  end

  it 'reads the limit of the assistant from ASSISTANT_THROTTLE_LIMIT' do
    ENV['ASSISTANT_THROTTLE_LIMIT'] = '250'
    load_initializer

    expect(Rack::Attack.throttles.fetch('assistant/ip').limit).to eq 250
  end
end
