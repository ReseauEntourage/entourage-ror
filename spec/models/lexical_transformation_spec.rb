require 'rails_helper'

RSpec.describe LexicalTransformation, type: :model do
  describe '#vectorizes' do
    let!(:neighborhood) { create(:neighborhood) }
    let(:lexical_transformation) { neighborhood.lexical_transformation }

    it 'enqueues BertJob' do
      expect(BertJob).to receive(:perform_later).with(lexical_transformation.id)

      lexical_transformation.vectorizes
    end
  end
end
