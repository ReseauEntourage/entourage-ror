require 'factory_girl'
require 'webmock/rspec'
require 'fakeredis/rspec'
require 'sidekiq/testing'
require 'super_diff/rspec'
Sidekiq::Testing.inline!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
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

ENV["DISABLE_CRYPT"]="TRUE"
ENV['ENTOURAGE_SECRET'] = 'test_entourage_secret'
API_HOST = 'api.entourage.test'
