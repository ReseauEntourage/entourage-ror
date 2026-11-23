require 'rails_helper'

describe Api::V1::Assistant::GroupsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token' }
  let!(:group) { create :neighborhood, name: 'Foot Paris 17è' }

  def call_route(key:, token:, params: {})
    @controller = described_class.new
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: { id: group.uuid_v2 }.merge(params)
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/groups/:id' do
    expect(get: '/api/v1/assistant/groups/abc').to route_to('api/v1/assistant/groups#read', id: 'abc')
  end

  context 'when it runs' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    def read(id)
      @controller = described_class.new
      request.headers['X-API-KEY'] = 'assistant-secret-key'
      request.headers['Authorization'] = "Bearer #{user.token}"
      get :read, params: { id: id }
    end

    it 'returns the id and the name of the group, and nothing else' do
      read(group.uuid_v2)

      expect(JSON.parse(response.body)).to eq('id' => group.uuid_v2, 'name' => 'Foot Paris 17è')
    end

    it 'finds the group by its numeric id too' do
      read(group.id)

      expect(JSON.parse(response.body)['id']).to eq(group.uuid_v2)
    end

    it 'does not show a group reserved to women to a man, as the app does not offer it' do
      group.update_columns(reserved_female: true)
      user.update!(gender: 'male')

      expect { read(group.uuid_v2) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not find an unknown group' do
      expect { read('unknown') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
