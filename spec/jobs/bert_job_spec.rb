require 'rails_helper'

RSpec.describe BertJob, type: :job do
  describe '#perform' do
    let(:neighborhood) { create(:neighborhood) }
    let(:lexical_transformation) { neighborhood.lexical_transformation }
    let(:field) { :name }
    let(:text) { "Some text" }
    let(:embedded) { [0.1, 0.2, 0.3] }

    before do
      allow_any_instance_of(LexicalTransformation).to receive(:performed?).and_return(false)
      allow_any_instance_of(LexicalTransformation).to receive(:update)
      allow_any_instance_of(LexicalTransformation).to receive(:instance).and_return(neighborhood)
      allow_any_instance_of(neighborhood.class).to receive(field).and_return(text)
      allow_any_instance_of(BertJob).to receive(:embedding).and_return(embedded)
    end

    it 'updates the lexical transformation with embedded text' do
      expect_any_instance_of(LexicalTransformation).to receive(:update).with("#{field}": embedded, performed: true)

      BertJob.new.perform(lexical_transformation.id, field)
    end

    it 'does not process if the transformation is already performed' do
      allow_any_instance_of(LexicalTransformation).to receive(:performed?).and_return(true)

      expect_any_instance_of(LexicalTransformation).not_to receive(:update)

      BertJob.new.perform(lexical_transformation.id, field)
    end
  end

  describe '#embedding' do
    let(:subject) { BertJob.new.embedding(text) }

    let(:text) { "Some text" }
    let(:command) { "python3 pycall/huggingface_encoder.py \"#{Shellwords.escape(text)}\"" }

    it 'parses JSON output from the Python script' do
      allow(Open3).to receive(:capture3).with(command).and_return(['[0.1, 0.2, 0.3]', '', double(success?: true)])

      expect(subject).to eq([0.1, 0.2, 0.3])
    end

    it 'logs an error if the Python script fails' do
      allow(Open3).to receive(:capture3).with(command).and_return(['', 'error message', double(success?: false)])

      expect(Rails.logger).to receive(:error).with('Error running python script: error message')
      expect(subject).to be_nil
    end

    it 'returns nil if JSON parsing fails' do
      allow(Open3).to receive(:capture3).with(command).and_return(['invalid json', '', double(success?: true)])

      expect(subject).to be_nil
    end
  end
end
