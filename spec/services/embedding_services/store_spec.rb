require 'rails_helper'

describe EmbeddingServices::Store do
  let(:client) { instance_double(OpenAI::Client) }
  let(:store) { described_class.new(client: client) }
  let(:resource) { create(:resource, name: 'Comment aider', description: 'Les premiers pas') }
  let(:neighborhood) { create(:neighborhood, name: 'Foot', description: 'Le dimanche') }

  def vector_for text
    [text.size.to_f] + [0.0] * (described_class::DIMENSIONS - 1)
  end

  before do
    allow(client).to receive(:embeddings) do |parameters:|
      { 'data' => parameters[:input].each_with_index.map { |text, index| { 'index' => index, 'embedding' => vector_for(text) } }.reverse }
    end
  end

  describe '#vectors_for' do
    subject { store.vectors_for([resource, neighborhood]) }

    it 'embeds the records and stores their embeddings' do
      expect(subject).to eq(resource => vector_for("Comment aider\nLes premiers pas"), neighborhood => vector_for("Foot\nLe dimanche"))

      expect(client).to have_received(:embeddings).once.with(parameters: {
        model: 'text-embedding-3-small', dimensions: 512, input: ["Comment aider\nLes premiers pas", "Foot\nLe dimanche"]
      })
      expect(Embedding.pluck(:embeddable_type, :embeddable_id, :model)).to match_array([
        ['Resource', resource.id, 'text-embedding-3-small'],
        ['Neighborhood', neighborhood.id, 'text-embedding-3-small']
      ])
    end

    context 'when the records were already embedded' do
      before { store.vectors_for([resource, neighborhood]) }

      it 'reuses the stored embeddings' do
        expect(subject[resource].first).to eq("Comment aider\nLes premiers pas".size)
        expect(client).to have_received(:embeddings).once
      end
    end

    context 'when the text of a record changed since its embedding' do
      before do
        store.vectors_for([resource, neighborhood])
        neighborhood.update!(description: 'Le dimanche matin')
      end

      it 'embeds this record again' do
        expect(subject[neighborhood].first).to eq("Foot\nLe dimanche matin".size)
        expect(client).to have_received(:embeddings).with(parameters: hash_including(input: ["Foot\nLe dimanche matin"]))
        expect(Embedding.count).to eq(2)
      end
    end

    context 'when a record has no text' do
      let(:outing) { build(:outing, title: '', description: nil) }

      it { expect(store.vectors_for([outing])).to eq({}) }
    end

    context 'when a record is destroyed' do
      before { store.vectors_for([resource, neighborhood]) }

      it 'deletes its embedding' do
        expect { resource.destroy }.to change(Embedding, :count).by(-1)
      end
    end
  end

  describe '.similarity' do
    it { expect(described_class.similarity([0.6, 0.8], [0.8, 0.6])).to be_within(0.001).of(0.96) }
  end
end
