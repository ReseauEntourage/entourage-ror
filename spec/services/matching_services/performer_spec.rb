require 'rails_helper'

describe MatchingServices::Performer do
  let(:paris) { { latitude: 48.86, longitude: 2.35 } }
  let(:user) { create(:ask_for_help_user) }
  let(:helper) { create(:offer_help_user) }

  let!(:action) { create(:solicitation, user: user, title: 'Besoin d\'un manteau', description: 'Pour cet hiver', section_list: ['clothes'], **paris) }
  let!(:coat) { create(:contribution, user: helper, title: 'Je donne un manteau chaud', section_list: ['clothes'], latitude: 48.865, longitude: 2.355) }
  let!(:guitar) { create(:contribution, user: helper, title: 'Cours de guitare', section_list: ['social'], latitude: 48.865, longitude: 2.355) }
  let!(:outing) { create(:outing, :outing_class, user: helper, title: 'Atelier vêtements chauds', **paris) }

  let(:openai_request) { action.openai_request }
  let(:client) { instance_double(OpenAI::Client) }
  let(:responses) { double(:responses) }

  let(:llm_recommandations) { [
    { type: 'outing', id: outing.id.to_s, explanation: 'Un atelier pour trouver des vêtements chauds.' },
    { type: 'contribution', id: '0', explanation: 'Un candidat qui ne fait pas partie de la liste.' },
    { type: 'contribution', id: coat.id.to_s, explanation: 'Une personne donne un manteau près de chez vous.' }
  ] }
  let(:llm_response) { {
    'id' => 'resp_123',
    'status' => 'completed',
    'output' => [
      { 'type' => 'reasoning', 'summary' => [] },
      { 'type' => 'message', 'role' => 'assistant', 'content' => [{ 'type' => 'output_text', 'text' => { recommandations: llm_recommandations }.to_json }] }
    ]
  } }

  # texts about warm clothes share a direction, the others are orthogonal to them
  def vector_for text
    text.match?(/manteau|vêtement/i) ? [1.0] + [0.0] * 511 : [0.0, 1.0] + [0.0] * 510
  end

  before do
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive(:embeddings) do |parameters:|
      { 'data' => parameters[:input].each_with_index.map { |text, index| { 'index' => index, 'embedding' => vector_for(text) } } }
    end
    allow(client).to receive(:responses).and_return(responses)
    allow(responses).to receive(:create).and_return(llm_response)
  end

  subject { described_class.new(openai_request: openai_request).perform }

  def matchings
    Matching.where(instance: action).order(:position).map { |matching| [matching.match_id, matching.position, matching.explanation] }
  end

  it 'saves the recommandations of the language model, in its order, ignoring unknown candidates' do
    subject

    expect(matchings).to eq([
      [outing.id, 0, 'Un atelier pour trouver des vêtements chauds.'],
      [coat.id, 1, 'Une personne donne un manteau près de chez vous.']
    ])
    expect(Matching.where(instance: action).pluck(:score)).to all(be_between(0, 1))
  end

  it 'only sends the shortlist to the language model, with the action described by the prompt' do
    subject

    expect(responses).to have_received(:create) do |parameters:|
      expect(parameters[:model]).to eq('gpt-6-luna')
      expect(parameters[:input].first[:content].first[:text]).to include('Besoin d\'un manteau')

      candidates = JSON.parse(parameters[:input].first[:content].last[:text])['candidats']
      expect(candidates.size).to be <= MatchingServices::Scorer::SHORTLIST_SIZE
      expect(candidates.first).to include('type' => 'contribution', 'id' => coat.id.to_s, 'name' => 'Je donne un manteau chaud')
      expect(candidates.map { |candidate| candidate['id'] }).to include(outing.id.to_s, guitar.id.to_s)
    end
  end

  it 'records the run on the openai_request' do
    subject

    expect(openai_request.reload.status).to eq('success')
    expect(openai_request.error).to be_nil
    expect(openai_request.run_starts_at).to be_present
    expect(openai_request.run_ends_at).to be_present

    response = JSON.parse(openai_request.response)
    expect(response['engine']).to eq('hybrid')
    expect(response['rerank']).to include('enabled' => true, 'model' => 'gpt-6-luna', 'response_id' => 'resp_123')
    expect(response['candidates']).to include('contribution' => 2, 'outing' => 1)
    expect(openai_request.response_instance.display_result).to eq(2)
    expect(openai_request.response_valid?).to be(true)
  end

  it 'embeds the action and its candidates once' do
    subject

    expect(Embedding.where(embeddable_type: 'Entourage').pluck(:embeddable_id)).to include(action.id, coat.id, guitar.id, outing.id)
  end

  context 'when the language model fails' do
    before { allow(responses).to receive(:create).and_raise(Faraday::TimeoutError, 'timeout') }

    it 'saves the best candidates of the hybrid score with a template explanation' do
      subject

      expect(matchings.first(2)).to eq([
        [coat.id, 0, 'À 700 m · même catégorie que votre action'],
        [outing.id, 1, "Tout près · le #{I18n.l(1.day.from_now.to_date, format: '%-d %B', locale: :fr)}"]
      ])
      expect(openai_request.reload.status).to eq('success')
      expect(openai_request.error).to eq('timeout')
    end
  end

  context 'when the reranking is disabled' do
    before { allow(ENV).to receive(:[]).and_call_original }
    before { allow(ENV).to receive(:[]).with('MATCHING_RERANK').and_return('false') }

    it 'does not call the language model' do
      subject

      expect(responses).not_to have_received(:create)
      expect(matchings.first.first(2)).to eq([coat.id, 0])
    end
  end

  context 'when the matching runs again' do
    before { described_class.new(openai_request: openai_request).perform }

    let(:llm_recommandations) { [{ type: 'contribution', id: coat.id.to_s, explanation: 'Un manteau.' }] }

    it 'replaces the previous matchings' do
      expect { subject }.not_to change { Matching.where(instance: action).count }.from(1)
    end
  end

  context 'when there is no candidate' do
    before { [coat, guitar, outing].each(&:destroy) }

    it 'records an error' do
      subject

      expect(openai_request.reload.status).to eq('error')
      expect(openai_request.error).to eq('No candidate')
      expect(responses).not_to have_received(:create)
    end
  end
end
