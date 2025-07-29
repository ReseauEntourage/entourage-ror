require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::OutingsController do
  explanation 'Outings'
  header 'Content-Type', 'application/json'

  get '/api/v1/outings' do
    route_summary 'Find outings'

    parameter :token, 'User token', type: :string, required: true
    parameter :latitude, 'latitude', type: :number, required: false
    parameter :longitude, 'longitude', type: :number, required: false
    parameter :travel_distance, 'travel_distance', type: :number, required: false

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:outing) { FactoryBot.create(:outing) }
    let(:token) { user.token }
    let(:latitude) { 48.84 }
    let(:longitude) { 2.28 }
    let(:travel_distance) { 10 }

    context '200' do
      example_request 'Get outings' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outings')
      end
    end
  end

  get 'api/v1/outings/:id' do
    route_summary 'Get a outing'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:outing) { create :outing }
    let(:id) { outing.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get outing' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outing')
      end
    end
  end

  post 'api/v1/outings' do
    route_summary 'Creates a outing'

    parameter :token, type: :string, required: true

    with_options scope: :outing, required: false do
      parameter :title, required: true
      parameter :description
      parameter :event_url
      parameter :latitude, required: true
      parameter :longitude, required: true
      parameter :interests
      parameter :other_interest
      parameter :online
      parameter :recurrency
      parameter :entourage_image_id
      parameter :neighborhood_ids

      with_options scope: 'outing[metadata]', required: true do
        parameter :starts_at
        parameter :ends_at
        parameter :place_name
        parameter :street_address
        parameter :google_place_id
        parameter :place_limit
      end
    end

    let(:user) { FactoryBot.create(:pro_user) }
    let(:neighborhood_1) { create :neighborhood }
    let(:neighborhood_2) { create :neighborhood }
    let(:entourage_image) { FactoryBot.create(:entourage_image) }
    let!(:join_request_1) { FactoryBot.create(:join_request, joinable: neighborhood_1, user: user, status: :accepted) }
    let!(:join_request_2) { FactoryBot.create(:join_request, joinable: neighborhood_2, user: user, status: :accepted) }

    let(:raw_post) { {
      token: user.token,
      outing: {
        title: 'Apéro Entourage',
        latitude: 48.868959,
        longitude: 2.390185,
        neighborhood_ids: [neighborhood_1.id, neighborhood_2.id],
        interests: ['animaux', 'other'],
        other_interest: 'poterie',
        entourage_image_id: entourage_image.id,
        metadata: {
          starts_at: 1.day.from_now,
          ends_at: 1.day.from_now + 1.hour,
          place_name: 'Le Dorothy',
          street_address: '85 bis rue de Ménilmontant, 75020 Paris, France',
          google_place_id: 'ChIJFzXXy-xt5kcRg5tztdINnp0',
          place_limit: 5
        }
      }
    }.to_json }

    context '201' do
      example_request 'Create outing with recurrency' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('outing')
      end
    end
  end

  put 'api/v1/outings/:id' do
    route_summary 'Updates an outing'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options scope: :outing, required: false do
      parameter :title
      parameter :description
      parameter :event_url
      parameter :latitude
      parameter :longitude
      parameter :interests
      parameter :other_interest
      parameter :online
      parameter :recurrency
      parameter :entourage_image_id
      parameter :neighborhood_ids

      with_options scope: 'outing[metadata]', required: false do
        parameter :starts_at
        parameter :ends_at
        parameter :place_name
        parameter :street_address
        parameter :google_place_id
        parameter :place_limit
      end
    end

    let(:outing) { FactoryBot.create(:outing, :with_recurrence, user: user) }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:params) { { title: 'new title' } }

    let(:id) { outing.id }
    let(:raw_post) { {
      token: user.token,
      outing: params
    }.to_json }

    context '200' do
      example_request 'Update outing' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outing')
      end
    end

    context '200' do
      let(:params) { { recurrency: 0 } }

      example_request 'Cancel outing recurrency' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outing')
      end
    end

    context '200' do
      let(:params) { { recurrency: 14 } }

      example_request 'Update outing recurrency to every two weeks' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outing')
      end
    end
  end

  put 'api/v1/outings/:id/batch_update' do
    route_summary 'Batch updates an outing'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options scope: :outing, required: false do
      parameter :title
      parameter :description
      parameter :event_url
      parameter :latitude
      parameter :longitude
      parameter :interests
      parameter :other_interest
      parameter :online
      parameter :recurrency
      parameter :entourage_image_id
      parameter :neighborhood_ids

      with_options scope: 'outing[metadata]', required: false do
        parameter :starts_at
        parameter :ends_at
        parameter :place_name
        parameter :street_address
        parameter :google_place_id
        parameter :place_limit
      end
    end

    let(:outing) { FactoryBot.create(:outing, user: user) }
    let!(:join_request) { FactoryBot.create(:join_request, joinable: outing, user: user, status: :accepted) }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:params) { { title: 'new title' } }

    let(:id) { outing.id }
    let(:raw_post) { {
      token: user.token,
      outing: params
    }.to_json }

    context '200' do
      example_request 'Update outing future siblings' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outings')
      end
    end
  end

  post 'api/v1/outings/:id/cancel' do
    route_summary 'Cancel a outing'

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:id) { outing.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:outing) { create(:outing, user: user) }

    let!(:join_request) { create(:join_request, user: outing.user, joinable: outing, status: :accepted, role: :organizer) }

    let(:raw_post) { {
      token: user.token,
      outing: {
        cancellation_message: :foo
      }
    }.to_json }

    context '200' do
      example_request 'Cancel outing' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('outing')
        expect(outing.reload.status).to eq('cancelled')
      end
    end

    context '401' do
      let(:outing) { create(:outing, user: FactoryBot.create(:pro_user)) }

      example_request 'Cancel outing without being the creator' do
        expect(response_status).to eq(401)
      end
    end
  end
end
