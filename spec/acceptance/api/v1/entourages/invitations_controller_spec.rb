require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::Entourages::InvitationsController do
  explanation "Invitations"
  header "Content-Type", "application/json"

  post '/api/v1/entourages/:entourage_id/invitations' do
    route_summary "Create invitations"
    # route_description "no description"

    parameter :token, type: :string, required: true
    parameter :entourage_id, type: :integer, required: true

    with_options scope: :invitation, required: true do
      parameter :mode, "SMS or partner_following", required: true
      parameter :phone_numbers, '[array]', type: :array, required: true
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:entourage) { FactoryBot.create(:entourage) }
    let(:entourage_id) { entourage.id }

    let(:raw_post) { {
      token: user.token,
      invite: {
        mode: "SMS",
        phone_numbers: ["+33612345678", "+33612345679"]
      }
    }.to_json }

    context '201' do
      let!(:join_request) { FactoryBot.create(:join_request, joinable: entourage, user: user, status: :accepted) }

      example_request 'Create invitations' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('successfull_numbers')
      end
    end

    context '403' do
      example_request 'Cannot create invitations if the user does not belong to the entourage' do
        expect(response_status).to eq(403)
      end
    end
  end
end
