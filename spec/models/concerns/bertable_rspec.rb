require 'rails_helper'

RSpec.describe Bertable, type: :module do
  let(:instance) { create(:contribution) }

  describe '#bertable_field_changed?' do
    it 'returns true if any bertable fields have changed' do
      instance.title = 'New Title'
      instance.save

      expect(instance.bertable_field_changed?).to be true
    end

    it 'returns false if no bertable fields have changed' do
      instance.save

      expect(instance.bertable_field_changed?).to be false
    end
  end

  describe "bert_on_save" do
    context "on create" do
      let(:instance) { build(:contribution) }

      it { expect { instance.save }.to change(LexicalTransformation, :count).by(1) }

      context "receives bert_on_save" do
        after { instance.save }

        it { expect_any_instance_of(Action).to receive(:bert_on_save) }
      end
    end

    context "on update" do
      let!(:instance) { create(:contribution) }

      it { expect { instance.update(title: :foo) }.not_to change(LexicalTransformation, :count) }

      context "receives bert_on_save" do
        after { instance.update(title: :foo) }

        it { expect_any_instance_of(Action).to receive(:bert_on_save) }
      end

      context "change postal_code does not trigger bert_on_save" do
        after { instance.update(postal_code: :foo) }

        it { expect_any_instance_of(Action).not_to receive(:bert_on_save) }
      end
    end
  end

  describe Bertable::BertStruct do
    let(:bert_struct) { instance.bert }

    describe '#on_save' do
      it 'ensures lexical_transformation exists and vectorizes' do
        expect(bert_struct).to receive(:ensure_lexical_transformation_exists!)
        expect(instance.lexical_transformation).to receive(:vectorizes)

        bert_struct.on_save
      end
    end

    describe '#ensure_lexical_transformation_exists!' do
      context 'when lexical_transformation exists and is persisted' do
        it 'does nothing' do
          lexical_transformation = double('LexicalTransformation', persisted?: true)
          allow(instance).to receive(:lexical_transformation).and_return(lexical_transformation)

          expect(lexical_transformation).not_to receive(:save!)

          bert_struct.ensure_lexical_transformation_exists!
        end
      end

      context 'when lexical_transformation does not exist or is not persisted' do
        it 'builds and saves a new lexical_transformation' do
          lexical_transformation = double('LexicalTransformation', persisted?: false)
          allow(instance).to receive(:lexical_transformation).and_return(lexical_transformation)
          allow(lexical_transformation).to receive(:save!)

          bert_struct.ensure_lexical_transformation_exists!

          expect(lexical_transformation).to have_received(:save!)
        end
      end
    end

    describe '#similars' do
      it 'returns similar lexical_transformations' do
        allow(LexicalTransformation).to receive(:find_by_sql).and_return(instance.lexical_transformation)

        expect(bert_struct.similars).to eq(instance.lexical_transformation)
      end
    end
  end
end
