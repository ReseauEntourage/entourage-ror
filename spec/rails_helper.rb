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

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
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
