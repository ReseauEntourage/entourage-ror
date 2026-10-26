require 'rails_helper'

describe ActiveModel::Serializer::I18nSerializer do
  describe '#translation' do
    let(:chat_message) { create(:chat_message, content: 'Bonjour') }

    before { Translation.find_or_initialize_by(instance: chat_message).update!(en: { content: translated }) }

    subject { described_class.new(chat_message.reload, :content, :en).translation }

    context 'translated' do
      let(:translated) { 'Hello' }

      it { expect(subject).to eq('Hello') }
    end

    context 'failed translation stored as an empty string' do
      let(:translated) { '' }

      it { expect(subject).to eq('Bonjour') }
    end

    context 'failed translation of html content stored as bare tags' do
      let(:translated) { '<p></p>' }

      it { expect(subject).to eq('Bonjour') }
    end
  end
end
