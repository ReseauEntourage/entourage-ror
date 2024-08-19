require 'rails_helper'

RSpec.describe Bertable, type: :module do
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
end
