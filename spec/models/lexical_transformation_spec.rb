require 'rails_helper'

RSpec.describe LexicalTransformation, type: :model do
  describe '#vectorizes' do
    let!(:neighborhood) { create(:neighborhood) }
    let(:lexical_transformation) { neighborhood.lexical_transformation }
    let(:fields) { [:name, :description] }

    it 'enqueues BertJob for each field' do
      fields.each do |field|
        expect(BertJob).to receive(:perform_later).with(lexical_transformation.id, field)
      end

      lexical_transformation.vectorizes
    end
  end
end
