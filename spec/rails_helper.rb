ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  config.backtrace_exclusion_patterns = [
    /vendor/
  ]

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
    SlackServices::StackTrace.any_instance.stub(:notify).and_return(nil)
  end
end

RspecApiDocumentation.configure do |config|
  config.disable_dsl_status!
  config.docs_dir = Rails.root.join("public", "doc", "api")
end

Geocoder.configure(lookup: :test, ip_lookup: :test)
Geocoder::Lookup::Test.add_stub(
  "174 rue Championnet, Paris", [{
    'coordinates'  => [49, 2.3],
    'address'      => '174 rue Championnet, Paris',
    'country'      => 'France',
    'country_code' => 'FR'
  }]
)

Geocoder::Lookup::Test.add_stub(
  "Au 50 75008 Paris", [{
    'coordinates'  => [48.870424, 2.30681949999996],
    'address'      => 'Au 50 75008 Paris',
    'country'      => 'France',
    'country_code' => 'FR'
  }]
)
