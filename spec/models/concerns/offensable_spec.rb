require 'rails_helper'

RSpec.describe Offensable, type: :model do
  let(:messageable) { create(:outing) }
  let(:chat_message) { create(:chat_message, content: 'Hello', messageable: messageable) }
  let(:offense_instance) { instance_double(Offensable::OffenseStruct, on_save: nil) }

  describe '#offense_on_save' do
    before { allow(chat_message).to receive(:offense).and_return(offense_instance) }
    before { allow(SensitiveWordsService).to receive(:has_match?).and_return(has_sensitive_words) }
    before { chat_message.send(:offense_on_save) }

    context 'when content does not contain sensitive words' do
      let(:has_sensitive_words) { false }

      it { expect(chat_message.offense).not_to have_received(:on_save) }
    end

    context 'when content contains sensitive words' do
      let(:has_sensitive_words) { true }

      it { expect(chat_message.offense).to have_received(:on_save) }
    end

    context 'when messageable is a conversation' do
      let(:messageable) { create(:conversation) }
      let(:has_sensitive_words) { true }

      it { expect(chat_message.offense).not_to have_received(:on_save) }
    end

    context 'when messageable is a outing' do
      let(:messageable) { create(:outing) }
      let(:has_sensitive_words) { true }

      it { expect(chat_message.offense).to have_received(:on_save) }
    end

    context 'when messageable is a neighborhood' do
      let(:messageable) { create(:neighborhood) }
      let(:has_sensitive_words) { true }

      it { expect(chat_message.offense).to have_received(:on_save) }
    end
  end
end
