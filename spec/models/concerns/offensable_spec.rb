require 'rails_helper'

RSpec.describe Offensable, type: :model do
  let(:messageable) { create(:outing) }
  let(:chat_message) { create(:chat_message, content: 'Hello', messageable: messageable) }
  let(:sensitive_service) { class_double('SensitiveWordsService').as_stubbed_const }
  let(:openai_request) { instance_double('OpenaiRequest') }

  before do
    allow(chat_message).to receive(:offense).and_return(openai_request)
    allow(openai_request).to receive(:on_save)
  end

  describe '#offense_on_save' do
    before {
      allow(sensitive_service).to receive(:has_match?).with(chat_message.content, :all, SensitiveWord::OFFENSABLE_CATEGORIES).and_return(has_sensitive_words)

      chat_message.send(:offense_on_save)
    }

    context 'when content does not contain sensitive words' do
      let(:has_sensitive_words) { false }

      it { expect(openai_request).not_to have_received(:on_save) }
    end

    context 'when content contains sensitive words' do
      let(:has_sensitive_words) { true }

      it { expect(openai_request).to have_received(:on_save) }
    end

    context 'when messageable is a conversation' do
      let(:messageable) { create(:conversation) }
      let(:has_sensitive_words) { true }

      it { expect(openai_request).not_to have_received(:on_save) }
    end

    context 'when messageable is a outing' do
      let(:messageable) { create(:outing) }
      let(:has_sensitive_words) { true }

      it { expect(openai_request).to have_received(:on_save) }
    end

    context 'when messageable is a neighborhood' do
      let(:messageable) { create(:neighborhood) }
      let(:has_sensitive_words) { true }

      it { expect(openai_request).to have_received(:on_save) }
    end
  end
end
