# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::SuggestionsController, type: :controller do
  render_views

  let(:user)    { create(:public_user, :paris) }
  let(:address) { user.address }
  let(:result)  { JSON.parse(response.body) }

  describe 'GET #index — authentication' do
    describe 'without token' do
      before { get(:index) }

      it { expect(response.status).to eq(401) }
    end
  end

  describe 'GET #index — valid response' do
    let!(:outings) do
      create_list(:outing, 3,
        latitude:  address.latitude,
        longitude: address.longitude,
        status:    'open',
        metadata:  { starts_at: 7.days.from_now.iso8601 })
    end

    before do
      # Stub finder to return only the created outings and avoid DB/PostGIS issues
      allow_any_instance_of(SuggestionServices::Finder).to receive(:candidates).and_return(outings)
      get(:index, params: { token: user.token })
    end

    it { expect(response.status).to eq(200) }

    it 'returns lifecycle_segment key' do
      expect(result).to have_key('lifecycle_segment')
    end

    it 'returns suggestions as an Array' do
      expect(result['suggestions']).to be_an(Array)
    end

    it 'returns meta with pagination keys' do
      expect(result['meta']).to include('current_page', 'total_pages', 'total_count')
    end

    it 'returns suggestion items with expected shape' do
      next if result['suggestions'].empty?

      suggestion = result['suggestions'].first
      expect(suggestion).to include('id', 'type', 'score', 'reasons')
    end
  end

  describe 'GET #index — already-joined outings are excluded' do
    let!(:joined_outing) do
      create(:outing,
        latitude:  address.latitude,
        longitude: address.longitude,
        status:    'open',
        metadata:  { starts_at: 7.days.from_now.iso8601 })
    end

    before do
      create(:join_request, user: user, joinable: joined_outing, status: 'accepted')
      allow_any_instance_of(SuggestionServices::Finder).to receive(:candidates).and_return([])
      get(:index, params: { token: user.token })
    end

    it 'does not include the joined outing in suggestions' do
      ids = result['suggestions'].map { |s| s['id'] }
      expect(ids).not_to include("outing_#{joined_outing.id}")
    end
  end
end
