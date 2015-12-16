require 'simplecov'
SimpleCov.start
require 'factory_girl'
require 'webmock/rspec'
require 'fakeredis/rspec'
require 'coveralls'
Coveralls.wear!

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
    mocks.verify_partial_doubles = true
  end

  config.tty = true
  config.color = true
  config.formatter = :documentation

  config.before(:each) { ActionMailer::Base.deliveries.clear }
end
