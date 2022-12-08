require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::UsersController do
  explanation "Users"
  header "Content-Type", "application/json"

  ENV['ADMIN_HOST'] = 'https://this.is.local'
  ENV['SLACK_SIGNAL'] = '{"url":"https://url.to.slack.com","channel":"channel"}'

  before(:each) {
    ENV['SLACK_WEBHOOK_URL'] = 'https://url.to.slack.com'
    stub_request(:post, "https://url.to.slack.com").to_return(status: 200)
  }

  after(:each) {
    ENV['SLACK_WEBHOOK_URL'] = nil
  }

  post '/api/v1/login' do
    route_summary "Login"
    # route_description "no description"

    parameter :phone, "Phone", type: :string, required: true
    parameter :sms_code, "SMS code", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user, sms_code: "123456") }

    let(:raw_post) { {
      format: :json,
      user: {
        phone: user.phone,
        sms_code: "123456"
      }
    }.to_json }

    context '200' do
      before { ENV["DISABLE_CRYPT"] = "FALSE" }
      after { ENV["DISABLE_CRYPT"] = "TRUE" }

      example_request 'Login' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  patch '/api/v1/users/:id' do
    route_summary 'Update'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :user, :required => true do
      parameter :first_name, "First name", type: :string, :required => false
      parameter :last_name, "Last name", type: :string, :required => false
      parameter :email, "Email", type: :string, :required => false
      parameter :sms_code, "SMS code", type: :string, :required => false
      parameter :phone, "Phone", type: :string, :required => false
      parameter :avatar_key, "Avatar key", type: :string, :required => false
      parameter :about, "About", type: :string, :required => false
      parameter :goal, "offer_help, ask_for_help, organization", type: :string, :required => false
      parameter :interests, "Interests", type: :array, :required => false
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id }

    let(:raw_post) { {
      token: user.token,
      user: {
        first_name: "foo",
        interests: [:sport]
      }
    }.to_json }

    context '200' do
      example_request 'Update user' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  post '/api/v1/users' do
    route_summary "Creates an action"

    parameter :token, type: :string, required: true

    with_options :scope => :user, :required => true do
      parameter :first_name, "First name", type: :string
      parameter :last_name, "Last name", type: :string
      parameter :email, "Email", type: :string
      parameter :sms_code, "SMS code", type: :string, required: true
      parameter :phone, "Phone", type: :string
      parameter :avatar_key, "Avatar key", type: :string
      parameter :about, "About", type: :string
      parameter :goal, "offer_help, ask_for_help, organization", type: :string
      parameter :interests, "Interests", type: :array
    end

    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      user: {
        phone: '+33612345678',
      }
    }.to_json }

    context '201' do
      example_request 'Create user' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  patch '/api/v1/users/:id/code' do
    route_summary 'Generate new SMS code'

    parameter :id, required: true

    with_options :scope => :user, :required => true do
      parameter :phone, "Phone", type: :string
    end

    with_options :scope => :code do
      parameter :action, "regenerate", type: :string
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id }

    let(:raw_post) { {
      user: { phone: user.phone },
      code: { action: 'regenerate' }
    }.to_json }

    context '200' do
      example_request 'Generate new SMS code' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  post '/api/v1/users/request_phone_change' do
    route_summary "Request a new phone number"

    parameter :token, type: :string, required: true

    with_options :scope => :user, :required => true do
      parameter :current_phone, "Current phone", type: :string, required: true
      parameter :requested_phone, "Requested phone", type: :string, required: true
      parameter :email, "Email", type: :string
    end

    let!(:user) { FactoryBot.create(:pro_user, phone: '+33623456789') }

    let(:raw_post) { {
      user: {
        current_phone: '+33623456789',
        requested_phone: '+33698765432',
        email: 'my@email.com'
      }
    }.to_json }

    context '200' do
      example_request 'Request a new phone number' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('code')
        expect(JSON.parse(response_body)).to have_key('message')
      end
    end
  end

  get '/api/v1/users/:id' do
    route_summary "Get a user"

    parameter :id, "Either a user id or 'me'", required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:other_user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    let(:subject) { JSON.parse(response_body) }

    context '200' do
      let(:id) { user.id }

      example_request 'Get my user using id' do
        expect(response_status).to eq(200)
        expect(subject).to have_key('user')
        expect(subject['user']).to have_key('uuid')
      end
    end

    context '200' do
      let(:id) { "me" }

      example_request 'Get my user using me' do
        expect(response_status).to eq(200)
        expect(subject).to have_key('user')
        expect(subject['user']).to have_key('uuid')
      end
    end

    context '200' do
      let(:id) { other_user.id }

      example_request 'Get another user' do
        expect(response_status).to eq(200)
        expect(subject).to have_key('user')
        expect(subject['user']).not_to have_key('uuid')
      end
    end
  end

  get '/api/v1/users/unread' do
    route_summary "Get unread count"

    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }

    let(:subject) { JSON.parse(response_body) }

    context '200' do
      example_request 'Get unread count' do
        expect(response_status).to eq(200)
        expect(subject).to have_key('user')
        expect(subject['user']).to have_key('unread_count')
      end
    end
  end

  delete '/api/v1/users/:id' do
    route_summary "Delete a user"

    parameter :id, "My id", required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let(:id) { user.id }

    let(:raw_post) { {
      token: user.token
    }.to_json }

    context '200' do
      example_request 'Delete user' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('user')
      end
    end
  end

  post '/api/v1/users/:id/report' do
    route_summary "Reports a user"

    parameter :id, "Reported user id", type: :integer, required: true
    parameter :token, "Reportings user token", type: :string, required: true

    with_options :scope => :user_report, :required => true do
      parameter :message, "Message", type: :string
    end

    let(:reporting_user) { FactoryBot.create(:pro_user) }
    let(:reported_user) { FactoryBot.create(:pro_user) }
    let(:id) { reported_user.id }

    let(:raw_post) { {
      token: reporting_user.token,
      user_report: {
        message: 'Message',
      }
    }.to_json }

    context '201' do
      example_request 'Reports a user' do
        expect(response_status).to eq(201)
        expect(response_body).to eq('')
      end
    end
  end

  post '/api/v1/users/:id/presigned_avatar_upload' do
    route_summary "Upload new avatar"

    parameter :id, "My id or 'me'", type: :integer, required: true
    parameter :token, type: :string, required: true
    parameter :content_type, "image/jpeg, image/gif", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id }

    let(:raw_post) { {
      token: user.token,
      content_type: 'image/jpeg',
    }.to_json }

    context '200' do
      example_request 'Upload new avatar' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('avatar_key')
        expect(JSON.parse(response_body)).to have_key('presigned_url')
      end
    end
  end

  post '/api/v1/users/:id/address' do
    route_summary "Update user address"

    parameter :id, "Id or 'me'", type: :integer, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :address, :required => true do
      parameter :place_name, "Place name", type: :string
      parameter :latitude, "Latitude", type: :number
      parameter :longitude, "Longitude", type: :number
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:id) { user.id.to_s }

    let(:raw_post) { {
      token: user.token,
      address: {
        place_name: '75012',
        latitude: 48.84,
        longitude: 2.38
      }
    }.to_json }

    context '200' do
      example_request 'Update user address' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('address')
        expect(JSON.parse(response_body)).to have_key('firebase_properties')
      end
    end
  end

  post '/api/v1/users/lookup' do
    route_summary "Lookup for a phone number"

    parameter :id, "Id or 'me'", type: :integer, required: true
    parameter :token, type: :string, required: true
    parameter :phone, type: :string, required: true

    let(:user) { FactoryBot.create :public_user }

    let(:raw_post) { {
      token: user.token,
      phone: user.phone
    }.to_json }

    context '200' do
      example_request 'Lookup for a phone number' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('status')
      end
    end
  end

  get '/api/v1/users/:id/email_preferences' do
    route_summary "Update email preferences"

    parameter :id, required: true
    parameter :category, "Default: all", type: :string
    parameter :signature, "[user_id]", type: :string
    parameter :accepts_emails, type: :boolean

    let(:user) { FactoryBot.create(:public_user) }
    let(:id) { user.id }
    let(:category) { FactoryBot.create(:email_category).name }
    let(:signature) { SignatureService.sign(user.id) }

    context '200' do
      let(:accepts_emails) { false }

      example_request 'Unsubscribe' do
        expect(response_status).to eq(200)
        expect(response_body).to include('Désabonnement effectué')
      end
    end

    context '200' do
      let(:accepts_emails) { true }

      example_request 'Subscribe' do
        expect(response_status).to eq(200)
        expect(response_body).to include('Abonnement effectué')
      end
    end
  end

  get '/api/v1/users/:id/address_suggestion' do
    route_summary "Confirm address suggestion"

    parameter :id, required: true
    parameter :postal_code, type: :string
    parameter :signature, "[user_id]:[postal_code]", type: :string

    let(:user) { FactoryBot.create(:public_user) }
    let(:id) { user.id }
    let(:postal_code) { '75018' }
    let(:signature) { SignatureService.sign("#{user.id}:#{postal_code}") }

    context '200' do
      example_request 'Confirm address suggestion' do
        expect(response_status).to eq(200)
        expect(response_body).to include('Mettre à jour votre code postal')
      end
    end
  end

  # @deprecated
  # post '/api/v1/users/ethics_charter_signed' do
  #   route_summary "Sign the ethics chart"

  #   parameter :token, type: :string, required: true

  #   with_options :scope => :form_response, :required => true do
  #     parameter :user_id, "Encoded user id", type: :string, required: true

  #     with_options :scope => :answers, :required => true do
  #       parameter :hidden, type: :string
  #       parameter :type, "choice, choices", type: :string

  #       with_options :scope => :choice do
  #         parameter :label, type: :string
  #       end
  #       with_options :scope => :choices do
  #         parameter :labels, type: :string
  #       end
  #     end
  #   end

  #   let(:user) { FactoryBot.create :public_user }

  #   let(:raw_post) { {
  #     token: user.token,
  #     form_response: {
  #       user_id: UserServices::EncodedId.encode(user.id),
  #       answers: [{
  #         hidden: 'hidden value',
  #         type: :choice,
  #         choice: { label: 'label' }
  #       }, {
  #         type: :choices,
  #         choices: { labels: 'labels' }
  #       }]
  #     }
  #   }.to_json }

  #   context '200' do
  #     example_request 'Sign the ethics chart' do
  #       expect(response_status).to eq(200)
  #       expect(response_body).to eq('')
  #     end
  #   end
  # end

  get '/api/v1/organization_admin_redirect' do
    route_summary "Redirect to organization admin"

    parameter :id, required: true
    parameter :token, type: :string, required: true
    parameter :message, "webapp_logout or nil", type: :string

    let(:user) { FactoryBot.create(:partner_user) }
    let(:id) { user.id }
    let(:token) { user.token }
    let(:message) { 'message' }

    context '302' do
      example_request 'Redirect to organization admin' do
        expect(response_status).to eq(302)
      end
    end
  end
end
