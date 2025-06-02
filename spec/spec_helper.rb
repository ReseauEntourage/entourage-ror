require 'factory_bot'
require 'webmock/rspec'
require 'fakeredis/rspec'
require 'sidekiq/testing'
require 'super_diff/rspec'
Sidekiq::Testing.inline!

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
    mocks.verify_partial_doubles = true
  end

  config.tty = true
  config.color = true
  config.formatter = :documentation

  config.before(:each) do
    Timecop.return
  end
end

ENV['ADMIN_HOST'] = 'https://this.is.local'
ENV["DISABLE_CRYPT"] = "TRUE"
ENV['ENTOURAGE_SECRET'] = 'test_entourage_secret'
ENV['ENTOURAGE_USER_PHONE'] = '+33612345678'
ENV["SLACK_DEFAULT_INTERLOCUTOR"] = "laure"
ENV["MODERATOR_PHONE"] = "+33768037348"
ENV['SLACK_WEBHOOK_URL'] = "https://url.to.slack.com"
ENV["SLACK_SIGNAL"] = '{"url":"https://url.to.slack.com","channel":"channel","channel-associations":"channel-associations"}'
API_HOST = 'api.entourage.test'
