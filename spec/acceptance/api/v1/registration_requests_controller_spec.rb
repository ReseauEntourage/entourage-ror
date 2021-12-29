require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::RegistrationRequestsController do
  explanation "Registration requests"
  header "Content-Type", "application/json"

  post '/api/v1/registration_requests' do
    parameter :token, type: :string, required: true

    with_options :scope => :registration_request, :required => true do
      with_options :scope => "registration_request[organization]", :required => true do
        parameter :name
        parameter :description
        parameter :phone
        parameter :address
        parameter :local_entity
        parameter :email
        parameter :website_url
        parameter :logo_key
      end
      with_options :scope => "registration_request[user]", :required => true do
        parameter :first_name
        parameter :last_name
        parameter :email
        parameter :phone
      end
    end

    let(:user) { FactoryBot.create(:public_user) }
    let(:attributes) { {
      organization: {
        name: "foo",
        local_entity: "bar",
        address: "2, rue de l'Église",
        phone: "+33612345678",
        email: "some@email.com",
        website_url: "http://foobar.com",
        description: "lorem ipsum",
        logo_key: "some_key.jpg"
      },
      user: {
        first_name: "John",
        last_name: "Doe",
        phone: "+33612345678",
        email: "some@email.com"
      }
    } }

    let(:id) { tour_area.id }
    let(:raw_post) { {
      token: user.token,
      registration_request: attributes
    }.to_json }

    context '201' do
      example_request 'Create registration_request' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('registration_request')
      end
    end
  end
end
