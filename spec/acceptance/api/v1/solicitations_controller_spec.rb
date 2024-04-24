require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::SolicitationsController do
  explanation "Solicitations"
  header "Content-Type", "application/json"

  get '/api/v1/solicitations' do
    route_summary "Find solicitations"

    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:solicitation) { FactoryBot.create(:solicitation, title: "foobar") }
    let(:token) { user.token }

    context '200' do
      example_request 'Get solicitations' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('solicitations')
      end
    end
  end

  get 'api/v1/solicitations/:id' do
    route_summary "Get a solicitation"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:solicitation) { create :solicitation }
    let(:id) { solicitation.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get solicitation' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('solicitation')
      end
    end
  end

  post 'api/v1/solicitations' do
    route_summary "Creates a solicitation"

    parameter :token, type: :string, required: true

    with_options :scope => :solicitation, :required => true do
      parameter :title
      parameter :description

      with_options :scope => "solicitation[metadata]", :required => true do
        parameter :city
      end

      with_options :scope => "solicitation[location]", :required => true do
        parameter :latitude
        parameter :longitude
      end

      parameter :postal_code
      parameter :section, "Category: social, services, clothes, equipment or hygiene"
      parameter :recipient_consent_obtained
    end

    let(:solicitation) { build :solicitation }
    let(:solicitation_image) { FactoryBot.create :solicitation_image }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      solicitation: {
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
      example_request 'Create solicitation' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('solicitation')
      end
    end
  end

  patch 'api/v1/solicitations/:id' do
    route_summary "Updates a solicitation"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :solicitation, :required => true do
      parameter :title
      parameter :description

      with_options :scope => "solicitation[metadata]" do
        parameter :city
      end

      with_options :scope => "solicitation[location]" do
        parameter :latitude
        parameter :longitude
      end

      parameter :postal_code
      parameter :section, "Category: social, services, clothes, equipment or hygiene"
      parameter :recipient_consent_obtained
    end

    let(:solicitation) { FactoryBot.create(:solicitation, user: user) }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { solicitation.id }
    let(:raw_post) { {
      token: user.token,
      solicitation: {
        title: "new title",
      }
    }.to_json }

    context '200' do
      example_request 'Update solicitation' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('solicitation')
      end
    end
  end

  post 'api/v1/solicitations/:id/report' do
    route_summary "Sends an alert about a solicitation"

    parameter :id, required: true
    parameter :token, type: :string, required: true
    with_options :scope => :report, :required => true do
      parameter :signals, type: :array
      parameter :message, type: :string
    end

    let(:solicitation) { create :solicitation }
    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { solicitation.id }
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
      example_request 'Report solicitation' do
        expect(response_status).to eq(201)
      end
    end
  end
end
