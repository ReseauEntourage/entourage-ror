require 'rails_helper'
include AuthHelper

describe Admin::OutingsController do
  render_views

  let!(:super_admin) { super_admin_basic_login }
  let!(:outing) { create :outing, :outing_class, title: 'Café partagé' }

  describe 'GET #measures' do
    let(:subject_id) { outing.uuid_v2 }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('ASSISTANT_API_URL').and_return('https://assistant.example.org')
      allow(ENV).to receive(:[]).with('ASSISTANT_SERVICE_KEY').and_return('local-service-key')
    end

    def stub_measures(metrics)
      stub_request(:get, 'https://assistant.example.org/api/v1/measures')
        .with(query: { product: 'local', subject: subject_id }).to_return(status: 200, body: { subject: subject_id, metrics: metrics }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'shows the distribution given by the assistant, for the event, as a complement and not as a success' do
      stub_measures(fears: { status: 'ok', total: 12, distribution: [{ value: 'alone', count: 7 }, { value: 'nothing', count: 5 }] },
                    fit: { status: 'too_few_responses' }, feeling: { status: 'too_few_responses' })

      get :measures, params: { id: outing.id }

      expect(response.status).to eq(200)
      expect(response.body).to include('12 réponse(s)', 'alone', 'complètent la mesure du contact humain effectif')
      expect(response.body).to include('ne mesurent pas le succès de l')
    end

    it 'shows only that there are too few responses, nothing else, below the threshold' do
      stub_measures(fears: { status: 'too_few_responses', total: 3, distribution: [{ value: 'alone', count: 3 }] },
                    fit: { status: 'too_few_responses' }, feeling: { status: 'too_few_responses' })

      get :measures, params: { id: outing.id }

      expect(response.body.scan("Trop peu de réponses").size).to eq(3)
      expect(response.body).not_to include('alone')
      expect(response.body).not_to include('réponse(s)')
    end

    it 'says the results are not available when the assistant cannot be read' do
      stub_request(:get, 'https://assistant.example.org/api/v1/measures').with(query: hash_including(product: 'local')).to_return(status: 503)

      get :measures, params: { id: outing.id }

      expect(response.status).to eq(200)
      expect(response.body).to include('ne sont pas disponibles')
    end

    it 'asks the assistant for the event by its stable identifier, the one of the sheet of the outing' do
      stub = stub_measures(fears: { status: 'too_few_responses' }, fit: { status: 'too_few_responses' }, feeling: { status: 'too_few_responses' })

      get :measures, params: { id: outing.uuid_v2 }

      expect(stub).to have_been_requested.once
    end
  end

  describe 'GET #index' do
    it 'links each outing to its measures' do
      get :index

      expect(response.body).to include(measures_admin_outing_path(outing))
    end
  end
end
