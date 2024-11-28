require 'rails_helper'

RSpec.describe Matchable, type: :module do
  let(:action) { create(:contribution) }

  describe 'included methods' do
    it 'adds the required associations' do
      expect(Action.reflect_on_association(:openai_assistant).macro).to eq(:has_one)
      expect(Action.reflect_on_association(:matchings).macro).to eq(:has_many)
      expect(Action.reflect_on_association(:matches).macro).to eq(:has_many)
    end
  end

  describe '#matchable_field_changed?' do
    it 'returns true if any of the fields :title, :name, :description have changed' do
      action.update_attribute(:title, 'Updated Title')
      expect(action.matchable_field_changed?).to be true
    end

    it 'returns false if none of the specified fields have changed' do
      action.touch # Updates `updated_at` but no other fields
      expect(action.matchable_field_changed?).to be false
    end
  end

  describe '#match_on_save' do
    before do
      allow(action).to receive(:matchable_field_changed?).and_return(true)
      allow_any_instance_of(Matchable::MatchStruct).to receive(:on_save)
    end

    it 'calls match.on_save if matchable_field_changed? is true' do
      expect_any_instance_of(Matchable::MatchStruct).to receive(:on_save)
      action.save!
    end

    it 'does not call match.on_save if matchable_field_changed? is false' do
      allow(action).to receive(:matchable_field_changed?).and_return(false)
      expect_any_instance_of(Matchable::MatchStruct).not_to receive(:on_save)
      action.save!
    end
  end

  describe 'MatchStruct' do
    subject(:match_struct) { action.match }

    before { allow_any_instance_of(Action).to receive(:matchable_field_changed?).and_return(false) }

    describe '#on_save' do
      context 'when openai_assistant exists and is persisted' do
        let!(:openai_assistant) { action.create_openai_assistant(instance: action) }

        it 'does not create a new openai_assistant' do
          expect { match_struct.on_save }.not_to change(OpenaiAssistant, :count)
        end
      end

      context 'when openai_assistant does not exist' do
        context 'creates a new openai_assistant' do
          it { expect { match_struct.on_save }.to change(OpenaiAssistant, :count).by(1) }
        end

        context 'associates the openai_assistant to the correct instance' do
          before { match_struct.on_save }

          it { expect(OpenaiAssistant.where(instance: action).count).to eq(1) }
          it { expect(OpenaiAssistant.where(instance: action, instance_class: "Contribution").count).to eq(1) }
        end
      end
    end
  end
end
