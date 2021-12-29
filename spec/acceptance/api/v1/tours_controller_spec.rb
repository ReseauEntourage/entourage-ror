require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource Api::V1::ToursController do
  explanation "Tours"
  header "Content-Type", "application/json"

  get '/api/v1/tours' do
    route_summary "Public user can not list tours"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:public_user) }
    let!(:tour) { FactoryBot.create(:tour) }
    let(:token) { user.token }

    context '403' do
      example_request 'Get tours for public user' do
        expect(response_status).to eq(403)
      end
    end
  end

  get '/api/v1/tours' do
    route_summary "Public user can not list tours"
    # route_description "no description"

    parameter :token, "User token", type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let!(:tour) { FactoryBot.create(:tour) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get tours for pro user' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('tours')
      end
    end
  end

  post 'api/v1/tours' do
    route_summary "Create a tour"

    parameter :token, type: :string, required: true

    with_options :scope => :tour, :required => true do
      parameter :tour_type
      # @fixme require disable_dsl_status!
      # @see https://github.com/zipmark/rspec_api_documentation/issues/329#issuecomment-278681542
      # parameter :status
      parameter :vehicle_type
      parameter :distance
      parameter :start_time
    end

    let(:tour) { build :tour }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:raw_post) { {
      token: user.token,
      tour: {
        tour_type: tour.tour_type,
        status: tour.status,
        vehicle_type: tour.vehicle_type,
        distance: 123.456,
        start_time: '2016-01-01T19:09:06.000+01:00'
      }
    }.to_json }

    context '201' do
      example_request 'Create a tour' do
        expect(response_status).to eq(201)
        expect(JSON.parse(response_body)).to have_key('tour')
      end
    end
  end

  get 'api/v1/tours/:id' do
    route_summary "Get a tour"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:tour) { create :tour }
    let(:id) { tour.id }
    let(:user) { FactoryBot.create(:pro_user) }
    let(:token) { user.token }

    context '200' do
      example_request 'Get tour' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('tour')
      end
    end
  end

  patch 'api/v1/tours/:id' do
    route_summary "Updates an tour"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :tour, :required => true do
      parameter :tour_type
      # @fixme require disable_dsl_status!
      # @see https://github.com/zipmark/rspec_api_documentation/issues/329#issuecomment-278681542
      # parameter :status
      parameter :vehicle_type
      parameter :distance
      parameter :start_time
    end

    let(:tour) { FactoryBot.create(:tour, user: user) }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { tour.id }
    let(:raw_post) { {
      token: user.token,
      tour: {
        distance: 10.02
      }
    }.to_json }

    context '200' do
      example_request 'Update tour' do
        expect(response_status).to eq(200)
        expect(JSON.parse(response_body)).to have_key('tour')
      end
    end
  end

  patch 'api/v1/tours/:id' do
    route_summary "Updates an tour the user did not created"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    with_options :scope => :tour, :required => true do
      parameter :tour_type
      # @fixme require disable_dsl_status!
      # @see https://github.com/zipmark/rspec_api_documentation/issues/329#issuecomment-278681542
      # parameter :status
      parameter :vehicle_type
      parameter :distance
      parameter :start_time
    end

    let(:tour) { FactoryBot.create(:tour) }
    let(:user) { FactoryBot.create(:pro_user) }

    let(:id) { tour.id }
    let(:raw_post) { {
      token: user.token,
      tour: {
        distance: 10.02
      }
    }.to_json }

    context '403' do
      example_request 'Update tour that the user did not created' do
        expect(response_status).to eq(403)
      end
    end
  end

  put 'api/v1/tours/:id/read' do
    route_summary "Defines a tour as read"
    route_description "Defines a tour as read if the user is the creator"

    parameter :id, required: true
    parameter :token, type: :string, required: true

    let(:user) { FactoryBot.create(:pro_user) }
    let(:tour) { FactoryBot.create(:tour, user: user) }
    let(:id) { tour.id }
    let(:raw_post) { {
      token: user.token,
    }.to_json }

    context '204' do
      example_request 'Defines a tour as read' do
        expect(response_status).to eq(204)
      end
    end
  end
end
