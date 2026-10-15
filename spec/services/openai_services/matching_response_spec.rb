require 'rails_helper'

describe OpenaiServices::MatchingResponse do
  describe '#parsed_response' do
    subject { described_class.new(response: response).parsed_response }

    context 'when response is nil' do
      let(:response) { nil }

      it { expect(subject).to be_nil }
    end

    context 'when response has no content' do
      let(:response) { { 'content' => [] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is not "text"' do
      let(:response) { { 'content' => [{ 'type' => 'image', 'text' => { 'value' => '{"key":"value"}' } }] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is "text" but text is malformed' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => 'invalid json' } }] } }

      it { expect(subject).to be_nil }
    end

    context 'when content type is "text" and text contains valid JSON' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => '{"key":"value"}' } }] } }

      it { expect(subject).to eq({ 'key' => 'value' }) }
    end

    context 'when text contains extraneous data but valid JSON inside' do
      let(:response) { { 'content' => [{ 'type' => 'text', 'text' => { 'value' => 'Random text before ```json{"key":"value"}``` and after' } }] } }

      it { expect(subject).to eq({ 'key' => 'value' }) }
    end
  end

  describe 'responses of the hybrid matching' do
    let(:contribution) { create(:contribution) }
    let(:neighborhood) { create(:neighborhood) }
    let(:response) { {
      'engine' => 'hybrid',
      'recommandations' => [
        { 'type' => 'contribution', 'id' => contribution.id.to_s, 'score' => 0.8, 'explanation' => 'Proche' },
        { 'type' => 'neighborhood', 'id' => neighborhood.id.to_s, 'score' => 0.6, 'explanation' => 'Même centre d\'intérêt' }
      ]
    } }

    subject { described_class.new(response: response) }

    it { expect(subject.parsed_response).to eq(response) }
    it { expect(subject).to be_valid }
    it { expect(subject.display_result).to eq(2) }
    it 'finds the recommanded records' do
      records = []
      subject.each_recommandation { |record, _score, _explanation, _index| records << record }

      expect(records.map { |record| [record.class.base_class, record.id] }).to eq([[Entourage, contribution.id], [Neighborhood, neighborhood.id]])
    end
  end
end
