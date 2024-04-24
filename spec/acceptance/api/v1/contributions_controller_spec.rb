require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::ContributionsController do
  explanation "Contributions"
  header "Content-Type", "application/json"

  get '/api/v1/contributions' do
    route_summary "Find contributions"

    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:contribution) { FactoryBot.create(:contribution, title: "foobar") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get contributions' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('contributions')
      end
    end
  end

  get 'api/v1/contributions/:id' do
    route_summary "Get a contribution"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:contribution) { create :contribution }
    let(:id) { contribution.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get contribution' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('contribution')
      end
    end
  end

  post 'api/v1/contributions' do
    route_summary "Creates a contribution"

    parameter :token, type: :string, required: true

    with_options :scope => :contribution, :required => true do
      parameter :title
      parameter :description

      with_options :scope => "contribution[metadata]", :required => true do
        parameter :city
      end

      with_options :scope => "contribution[location]", :required => true do
        parameter :latitude
        parameter :longitude
      end

      parameter :postal_code
      parameter :section, "Category: social, services, clothes, equipment or hygiene"
      parameter :recipient_consent_obtained
    end

    let(:contribution) { build :contribution }
    let(:contribution_image) { FactoryBot.create :contribution_image }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      contribution: {
        title: "Apéro Entourage",
        description: "Au Social Bar",
        metadata: {
          city: 'Nantes',
        },
        postal_code: '44000',
        location: {
          latitude: 48.85,
          longitude: 2.4,
        },
        section: 'social',
        recipient_consent_obtained: true
      }
    }.to_json }

    context '201' do
      example_request 'Create contribution' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('contribution')
      end
    end
  end

  patch 'api/v1/contributions/:id' do
    route_summary "Updates a contribution"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :contribution, :required => true do
      parameter :title
      parameter :description

      with_options :scope => "contribution[metadata]" do
        parameter :city
      end

      with_options :scope => "contribution[location]" do
        parameter :latitude
        parameter :longitude
      end

      parameter :postal_code
      parameter :section, "Category: social, services, clothes, equipment or hygiene"
      parameter :recipient_consent_obtained
    end

    let(:contribution) { FactoryBot.create(:contribution, user: user) }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { contribution.id }
    let(:raw_post) { {
      token: user.token,
      contribution: {
        title: "new title",
      }
    }.to_json }

    context '200' do
      example_request 'Update contribution' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('contribution')
      end
    end
  end

  post 'api/v1/contributions/:id/report' do
    route_summary "Sends an alert about a contribution"

    parameter :id, required: true
    parameter :token, type: :string, required: true
    with_options :scope => :report, :required => true do
      parameter :signals, type: :array
      parameter :message, type: :string
    end

    let(:contribution) { create :contribution }
    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { contribution.id }
    let(:raw_post) { {
      token: user.token,
      report: {
        signals: ['spam'],
        message: 'message'
      }
    }.to_json }


    ENV['ADMIN_HOST'] = 'https://this.is.local'
    ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

    context '201' do
      example_request 'Report contribution' do
        expect(response_status).to eq(201)
      end
    end
  end
end
