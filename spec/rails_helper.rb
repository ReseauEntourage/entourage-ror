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

    stub_request(:any, /.*api.mailjet.com.*/).to_return(status: 200, body: { id: 1 }.to_json, headers: {})
    stub_request(:post, "https://url.to.slack.com").to_return(status: 200)

    # deactivate slack_trace notifications
    SlackServices::StackTrace.any_instance.stub(:notify).and_return(nil)

    # deactivate salesforce updates
    SalesforceJob.any_instance.stub(:perform).and_return(nil)

    # deactivate translation on create
    # TranslationObserver.any_instance.stub(:action).and_return(nil)
    [ChatMessage, Entourage, Neighborhood].each do |klass|
      # klass.any_instance.stub(:text_translation).and_return("foo")
      klass.any_instance.stub(:translate_field!).and_return("foo")
    end
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
Geocoder::Lookup::Test.add_stub(
  [1.5, 1.5], [{
    'coordinates'  => [1.5, 1.5],
    'address'      => 'rue Pizza',
    'city'         => 'Cassis',
    'postal_code'  => '13260',
    'country'      => 'France',
    'country_code' => 'FR'
  }]
)
Geocoder::Lookup::Test.add_stub(
  [45.2, 3.7], [{
    'coordinates'  => [45.2, 3.7],
    'address'      => 'rue Foo',
    'city'         => 'Paris',
    'postal_code'  => '75011',
    'country'      => 'France',
    'country_code' => 'FR'
  }]
)
Geocoder::Lookup::Test.add_stub(
  [44.7, 3.1], [{
    'coordinates'  => [44.7, 3.1],
    'address'      => 'rue Bar',
    'city'         => 'Paris',
    'postal_code'  => '92001',
    'country'      => 'France',
    'country_code' => 'FR'
  }]
)

Geocoder::Lookup::Test.set_default_stub([
  {
    'coordinates'  => [48.23, -4.56],
    'address'      => 'Pointe de Dinan, Crozon',
    'city'         => 'Crozon',
    'postal_code'  => '29160',
    'country'      => 'France',
    'country_code' => 'FR'
  }
])
