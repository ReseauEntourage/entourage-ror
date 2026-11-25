require 'rails_helper'

describe Api::V1::Assistant::ReferentController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token', goal: 'offer_help' }
  let(:body) { JSON.parse(response.body) }

  def call_route(key:, token:, params: {})
    request.headers['X-API-KEY'] = key if key
    request.headers['Authorization'] = "Bearer #{token}" if token
    get :read, params: params
  end

  it_behaves_like 'an assistant read'

  it 'is routed to GET /api/v1/assistant/referent' do
    expect(get: '/api/v1/assistant/referent').to route_to('api/v1/assistant/referent#read')
  end

  describe 'the dedicated contact' do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
    end

    let(:animator) { create :public_user, first_name: 'Nadia', last_name: 'Martin' }

    it 'returns the moderator that the app shows as the contact, with what is needed to warn them, and nothing else' do
      create :moderation_area, departement: '*', animator: animator
      create :address, user: user, postal_code: '75001'

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body).to eq('referent' => { 'id' => animator.uuid, 'displayName' => 'Nadia M.', 'warnedBy' => 'team_alert' })
      expect(response.body).not_to include(animator.phone)
      expect(response.body).not_to include(animator.email.to_s) if animator.email.present?
    end

    it 'is the same person as the one of the app (SummarySerializer#moderator)' do
      create :moderation_area, departement: '*', animator: animator

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body.dig('referent', 'id')).to eq(ModerationServices.moderator_for_user(user).uuid)
    end

    it 'is not the volunteer referent of the zone' do
      volunteer = create :public_user, first_name: 'Bénévole'
      create :moderation_area, departement: '*', animator: animator, referent_benevole: volunteer

      call_route(key: 'assistant-secret-key', token: user.token)

      expect(body.dig('referent', 'id')).to eq(animator.uuid)
    end

    it 'returns the absence of contact, without error and without inventing one' do
      call_route(key: 'assistant-secret-key', token: user.token)

      expect(response.status).to eq(200)
      expect(body).to eq('referent' => nil)
    end
  end
end
