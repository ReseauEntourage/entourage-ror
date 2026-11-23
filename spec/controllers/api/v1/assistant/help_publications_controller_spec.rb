require 'rails_helper'

describe Api::V1::Assistant::HelpPublicationsController, type: :controller do
  let(:user) { create :public_user, token: 'user-secret-token', first_name: 'Camille' }
  # The model only strips the description and squishes the title, as for any publication of the app.
  let(:text) { "Bonjour,  j'aurais besoin d'aide pour mes courses — merci !" }

  before { create :address, user: user, latitude: 48.85, longitude: 2.35, city: 'Paris' }

  describe 'publish_request' do
    def call_action(key:, api_key:, token:, params:)
      request.headers['X-API-KEY'] = api_key if api_key
      request.headers['Authorization'] = "Bearer #{token}" if token
      request.headers['Idempotency-Key'] = key if key
      post :publish_request, params: params, as: :json
    end

    let(:valid_params) { { title: 'Courses', description: text, category: 'services', recipientConsentObtained: true } }
    let(:other_params) { valid_params.merge(description: 'Bonjour, autre chose') }
    let(:action_type) { 'help_request.publish' }
    let(:subject_class) { Entourage }

    it_behaves_like 'an assistant action'

    it 'is routed to POST /api/v1/assistant/help_requests' do
      expect(post: '/api/v1/assistant/help_requests').to route_to('api/v1/assistant/help_publications#publish_request')
      expect(post: '/api/v1/assistant/help_offers').to route_to('api/v1/assistant/help_publications#publish_offer')
    end

    context 'when it runs' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
        allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')
      end

      def publish(params = valid_params, key: SecureRandom.uuid)
        @controller = described_class.new
        call_action(key: key, api_key: 'assistant-secret-key', token: user.token, params: params)
      end

      it 'publishes the request as the user would, with their words untouched, visible to the others' do
        publish

        solicitation = Solicitation.find_by!(uuid_v2: JSON.parse(response.body)['id'])
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to eq('id' => solicitation.uuid_v2, 'type' => 'request', 'status' => 'open')
        expect(solicitation).to have_attributes(user_id: user.id, title: 'Courses', description: text, status: 'open')
        expect(solicitation.section_list).to eq(['services'])
        expect([solicitation.latitude, solicitation.longitude]).to eq([48.85, 2.35])
        expect(Solicitation.active).to include(solicitation)
      end

      it 'is a publication like any other for the other members: the assistant leaves no trace on it' do
        publish
        solicitation = Solicitation.last
        from_app = create :solicitation, user: user

        assistant_json = V1::ActionSerializer.new(solicitation, scope: { user: create(:public_user) }, root: false).as_json
        app_json = V1::ActionSerializer.new(from_app, scope: { user: create(:public_user) }, root: false).as_json

        expect(assistant_json.keys).to eq(app_json.keys)
        expect(assistant_json.to_json.downcase).not_to include('assistant')
      end

      it 'is found by the team from assistant_actions (traceability)' do
        publish

        solicitation = Solicitation.last
        row = AssistantAction.find_by!(subject_type: 'Entourage', subject_id: solicitation.id)
        expect(row).to have_attributes(user_id: user.id, action_type: 'help_request.publish')
      end

      it 'publishes once when the request is replayed' do
        key = SecureRandom.uuid

        expect { 2.times { publish(key: key) } }.to change { Solicitation.unscoped.where(group_type: :action).count }.by(1)
      end

      it 'waits for the moderation, as in the app, when the consent of the person is not obtained' do
        publish(valid_params.except(:recipientConsentObtained))

        expect(Solicitation.unscoped.last.status).to eq('suspended')
      end

      it 'refuses what the validations of the app refuse' do
        publish(valid_params.merge(title: ''))

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']['code']).to eq('INVALID_PARAMS')
      end

      it 'refuses an invalid section with the reasons of the app' do
        publish(valid_params.merge(category: 'unknown'))

        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to include('code' => 'CANNOT_PUBLISH')
        expect(Solicitation.unscoped.where(title: 'Courses')).not_to exist
      end

      it 'publishes from the address of the user: the assistant gives no coordinates' do
        publish

        solicitation = Solicitation.last
        expect([solicitation.latitude, solicitation.longitude]).to eq([48.85, 2.35])
      end

      it 'refuses to publish when the user has no address to publish from' do
        user.update_columns(address_id: nil)

        publish

        expect([response.status, JSON.parse(response.body).dig('error', 'code')]).to eq([400, 'INVALID_PARAMS'])
        expect(Solicitation.unscoped.where(title: 'Courses')).not_to exist
      end
    end
  end

  describe 'publish_offer' do
    def call_action(key:, api_key:, token:, params:)
      request.headers['X-API-KEY'] = api_key if api_key
      request.headers['Authorization'] = "Bearer #{token}" if token
      request.headers['Idempotency-Key'] = key if key
      post :publish_offer, params: params, as: :json
    end

    let(:valid_params) { { title: 'Prêt de perceuse', description: text, category: 'equipment' } }
    let(:other_params) { valid_params.merge(description: 'Bonjour, autre chose') }
    let(:action_type) { 'help_offer.publish' }
    let(:subject_class) { Entourage }

    it_behaves_like 'an assistant action'

    it 'publishes the offer with the words of the user, open' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_KEY').and_return('assistant-secret-key')
      allow(ENV).to receive(:[]).with('ASSISTANT_ACTIONS_ENABLED').and_return('true')

      call_action(key: SecureRandom.uuid, api_key: 'assistant-secret-key', token: user.token, params: valid_params)

      contribution = Contribution.find_by!(uuid_v2: JSON.parse(response.body)['id'])
      expect(JSON.parse(response.body)).to include('type' => 'offer', 'status' => 'open')
      expect(contribution).to have_attributes(user_id: user.id, title: 'Prêt de perceuse', description: text)
    end
  end
end
