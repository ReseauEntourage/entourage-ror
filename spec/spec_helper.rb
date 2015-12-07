require 'simplecov'
SimpleCov.start
require 'factory_girl'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
    mocks.verify_partial_doubles = true
  end

  config.before(:each) { ActionMailer::Base.deliveries.clear }
end
