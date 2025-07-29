require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::NewsletterSubscriptionsController do
  explanation "Newsletter subscriptions"
  header "Content-Type", "application/json"

  post '/api/v1/newsletter_subscriptions' do
    route_summary "Create newsletter subscription"

    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    let(:raw_post) { {
      token: user.token,
      newsletter_subscription: {
        email: 'foo@bar.com',
        active: true
      }
    }.to_json }

    context '201' do
      before {
        stub_request(:post, "https://api.mailjet.com/v3/REST/contactslist/2822632/managecontact").to_return(
          status: 200,
          body: {
            count: 1,
            data: {
              name: "foo",
              properties: {
                newsletter_entourage: true,
                antenne_entourage: "NANTES",
                profil_entourage: "PARTICULIER"
              },
              action: "addnoforce",
              email: "foo@bar.fr"
            }
          }.to_json,
          headers: {}
        )
      }

      example_request 'Create newsletter subscription' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('message')
        expect(JSON.parse(response_body)).to eq({ "message" => "Contact foo@bar.com ajouté" })
      end
    end
  end
end
