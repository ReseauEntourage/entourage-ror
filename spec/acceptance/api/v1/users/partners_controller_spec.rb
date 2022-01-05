require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Users::PartnersController do
  explanation "Partners"
  header "Content-Type", "application/json"

  get '/api/v1/partners' do
  end
end
