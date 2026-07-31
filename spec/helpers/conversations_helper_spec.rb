require 'rails_helper'

RSpec.describe ConversationsHelper, type: :helper do
  describe '#format_chat_message_content' do
    let(:chat_message) { create(:chat_message, content: content) }
    let(:result) { helper.format_chat_message_content(chat_message) }

    context 'plain text content' do
      let(:content) { "Bonjour\ntout le monde" }

      it { expect(result).to eq(helper.simple_format(content)) }
      it { expect(result).to be_html_safe }
    end

    context 'rich text content (WYSIWYG output)' do
      let(:content) { '<p>Bonjour <strong>tout le monde</strong></p><ul><li>un</li><li>deux</li></ul>' }

      it { expect(result).to include('<strong>tout le monde</strong>') }
      it { expect(result).to include('<li>un</li>') }
      it { expect(result).to include('<li>deux</li>') }
      it { expect(result).to be_html_safe }
    end

    context 'content with a single allowed link tag' do
      let(:content) { '<a href="https://example.com">lien</a>' }

      it { expect(result).to eq(content) }
    end
  end

  describe '#chat_message_with_status' do
    let(:result) { helper.chat_message_with_status(chat_message) }

    context 'active message with rich text content' do
      let(:chat_message) { create(:chat_message, content: '<p>Bonjour <strong>monde</strong></p>') }

      it { expect(result).to include('<p>Bonjour <strong>monde</strong></p>') }
      it { expect(result).to include("id=\"chat-message-#{chat_message.id}\"") }
    end

    context 'active message with plain text content' do
      let(:chat_message) { create(:chat_message, content: 'Bonjour') }

      it { expect(result).to include('<p>Bonjour</p>') }
    end

    context 'deleted message' do
      let(:chat_message) do
        create(:chat_message, content: 'foo').tap do |message|
          message.update_columns(status: 'deleted', deleted_at: Time.current)
        end
      end

      it { expect(result).to include('Ce message a été supprimé') }
      it { expect(result).to include('foo') }
    end

    context 'offensible message' do
      let(:chat_message) do
        create(:chat_message, content: 'foo').tap { |message| message.update_column(:status, 'offensible') }
      end

      it { expect(result).to include('détecté automatiquement comme offensant') }
    end

    context 'offensive message' do
      let(:chat_message) do
        create(:chat_message, content: 'foo').tap { |message| message.update_column(:status, 'offensive') }
      end

      it { expect(result).to include('modéré comme offensant') }
    end

    context 'message with a foreign translation' do
      let(:chat_message) { create(:chat_message, content: 'foo') }

      before do
        translation = chat_message.reload.translation || create(:translation, instance: chat_message)
        translation.update!(from_lang: 'en')
      end

      it { expect(result).to include('Traduction') }
    end
  end
end
