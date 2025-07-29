require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::InvitationsController do
  explanation 'Invitations'
  header 'Content-Type', 'application/json'

  get '/api/v1/invitations' do
    parameter :token, type: :string, required: true
    parameter :status, 'accepted, cancelled, rejected, pending', type: :string

    let(:user) { FactoryBot.create(:public_user) }
    let(:token) { user.token }
    let!(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }

    context '200' do
      example_request 'Get user invitations' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('invitations')
      end
    end
  end

  patch '/api/v1/invitations/:id' do
    parameter :id, 'Invitation id', type: :integer, required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { invitation.id }
    let(:raw_post) { {
      token: user.token
    }.to_json }

    context 'Accept invitation' do
      let(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }

      example_request 'Accept invitation' do
        expect(response_status).to eq(204)
      end
    end
  end

  delete '/api/v1/invitations/:id' do
    parameter :id, 'Invitation id', type: :integer, required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }

    let(:id) { invitation.id }
    let(:raw_post) { {
      token: user.token
    }.to_json }

    context 'Delete invitation' do
      let(:invitation) { FactoryBot.create(:entourage_invitation, invitee: user) }

      example_request 'Delete invitation' do
        expect(response_status).to eq(204)
      end
    end
  end
end
