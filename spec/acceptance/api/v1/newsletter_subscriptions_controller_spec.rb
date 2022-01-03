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
      before { stub_request(:post, "https://us8.api.mailchimp.com/2.0/lists/subscribe.json").
          to_return(:status => 200, :body => "", :headers => {}) }
      example_request 'Create newsletter subscription' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('newsletter_subscription')
      end
    end
  end
end
