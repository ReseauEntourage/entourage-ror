require 'rails_helper'

describe Api::V1::Assistant::GroupMembershipsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let!(:group) { create :neighborhood, name: 'Foot Paris 17è' }

  def call_action(key:, api_key:, token:, params:)
    request.headers['X-API-KEY'] = api_key if api_key
    request.headers['Authorization'] = "Bearer #{token}" if token
    request.headers['Idempotency-Key'] = key if key
    post :join, params: params, as: :json
  end

  let(:valid_params) { { id: group.uuid_v2 } }
  let(:other_params) { { id: create(:neighborhood).uuid_v2 } }
  let(:action_type) { 'group.join' }
  let(:subject_class) { JoinRequest }

  it_behaves_like 'an assistant action'

  it 'is routed to POST /api/v1/assistant/groups/:id/join' do
    expect(post: '/api/v1/assistant/groups/abc/join').to route_to('api/v1/assistant/group_memberships#join', id: 'abc')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
    end

    def join(params = valid_params, key: SecureRandom.uuid)
      @controller = described_class.new
      call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: params)
    end

    it 'records the membership as the app does: accepted, as a member' do
      join

      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)).to eq('groupId' => group.uuid_v2, 'status' => 'joined')
      expect(JoinRequest.find_by(joinable: group, user: user)).to have_attributes(status: 'accepted', role: 'member')
    end

    it 'joins again a group that the user left' do
      create :join_request, joinable: group, user: user, status: :cancelled, role: :member

      join

      expect(JoinRequest.where(joinable: group, user: user).pluck(:status)).to eq(['accepted'])
    end

    it 'keeps a single membership when it is replayed, with the same key or another one' do
      key = SecureRandom.uuid

      join(key: key)
      join(key: key)
      join

      expect(JoinRequest.where(joinable: group, user: user).count).to eq(1)
    end

    it 'refuses an unknown group' do
      join({ id: 'unknown' })

      expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([404, 'NOT_FOUND'])
    end
  end
end
