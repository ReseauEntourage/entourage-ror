require 'rails_helper'

RSpec.describe Mentionable, type: :module do
  let(:chat_message) { create(:chat_message, content: content) }
  
  describe Mentionable::MentionsStruct do
    subject { Mentionable::MentionsStruct.new(instance: chat_message) }

    context 'when content contains HTML' do
      let(:content) { 'Hello, <a href="https://preprod.entourage.social/app/users/123">User</a>' }

      it 'detects HTML content' do
        expect(subject.contains_html?).to be true
      end

      it 'detects an anchor with href' do
        expect(subject.contains_anchor_with_href?).to be true
      end

      it 'detects a user link' do
        expect(subject.contains_user_link?).to be true
      end

      it 'extracts user UUIDs' do
        expect(subject.extract_user_ids_or_uuids).to eq(['123'])
      end

      it 'removes HTML for no_html' do
        expect(subject.no_html).to eq('Hello, User')
      end
    end

    context 'when content contains multiple HTML' do
      let(:content) { 'Hello, <a href="https://preprod.entourage.social/app/users/123">John</a> and <a href="https://preprod.entourage.social/app/users/456">Jane</a>' }

      it 'extracts user UUIDs' do
        expect(subject.extract_user_ids_or_uuids).to eq(['123', '456'])
      end

      it 'removes HTML for no_html' do
        expect(subject.no_html).to eq('Hello, John and Jane')
      end
    end

    context 'when content does not contain HTML' do
      let(:content) { 'Hello, User' }

      it 'does not detect HTML content' do
        expect(subject.contains_html?).to be false
      end

      it 'does not detect an anchor with href' do
        expect(subject.contains_anchor_with_href?).to be false
      end

      it 'does not detect a user link' do
        expect(subject.contains_user_link?).to be false
      end

      it 'extracts no user UUIDs' do
        expect(subject.extract_user_ids_or_uuids).to eq([])
      end
    end
  end

  describe '.no_html' do
    let(:result) { Mentionable.no_html(content) }

    context 'unchanged content for plain text' do
      let(:content) { 'text without HTML' }
      it { expect(result).to eq(content) }
    end

    context 'unchanged content for plain text with special caracters' do
      let(:content) { 'Texte avec des caractères spéciaux ! @ # $ % ^ & *' }
      it { expect(result).to eq(content) }
    end

    context 'remove <img> tags' do
      let(:content) { 'Texte avec <img src="image.jpg"> image' }
      it { expect(result).to eq('Texte avec  image') }
    end

    context 'replace <a> tags' do
      let(:content) { 'Visitez <a href="https://example.com">ce site</a> maintenant' }
      it { expect(result).to eq('Visitez ce site maintenant') }
    end

    context 'replace tags with plain text' do
      let(:content) { '<p>Section with <b>bold</b> text</p>' }
      it { expect(result).to eq('Section with bold text') }
    end

    context 'empty text' do
      let(:content) { '' }
      it { expect(result).to eq('') }
    end

    context 'nil' do
      let(:content) { nil }
      it { expect(result).to be_nil }
    end

    context 'replace embed tags' do
      let(:content) { '<div><p><a href="https://example.com">Click here</a></p></div>' }
      it { expect(result).to eq('Click here') }
    end

    context 'with malformed tags' do
      let(:content) { '<p>Text with malformed <b>tag' }
      it { expect(result).to eq('Text with malformed tag') }
    end

    context 'with special tag br' do
      let(:content) { 'Text with <br/> special tag' }
      it { expect(result).to eq("Text with \n special tag") }
    end

    context 'multiple tags' do
      let(:content) { '<div><h1>Title</h1><p>Section with <b>bold</b> and <i>italic</i></p></div>' }
      it { expect(result).to eq('TitleSection with bold and italic') }
    end
  end

  describe '.filter_html_tags' do
    let(:content) { 'Hello <strong>world</strong>! <a href="https://example.com">Click here</a><br>New line.' }
    let(:result) { Mentionable.filter_html_tags(content, allowed_tags) }

    context 'with specific tags (a, br, strong)' do
      let(:allowed_tags) { %w[a br strong] }

      it { expect(result).to eq('Hello <strong>world</strong>! <a href="https://example.com">Click here</a><br>New line.') }
    end

    context 'without allowed tags' do
      let(:allowed_tags) { [] }

      it { expect(result).to eq('Hello world! Click hereNew line.') }
    end

    context 'with default tags' do
      let(:result) { Mentionable.filter_html_tags(content) }

      it { expect(result).to eq('Hello world! <a href="https://example.com">Click here</a><br>New line.') }
    end

    context 'with plain text' do
      let(:content) { 'plain text' }
      let(:result) { Mentionable.filter_html_tags(content) }

      it { expect(result).to eq(content) }
    end

    context 'non string value' do
      it { expect(Mentionable.filter_html_tags(nil)).to eq(nil) }
      it { expect(Mentionable.filter_html_tags(123)).to eq(123) }
      it { expect(Mentionable.filter_html_tags(['test'])).to eq(['test']) }
    end

    context 'embedded tags' do
      let(:content) { '<p dir="ltr"><a href="https://preprod.entourage.social/app/users/3445">@</a>. Voici une mention </p>\n' }
      let(:result) { Mentionable.filter_html_tags(content) }

      it { expect(result).to eq('<a href="https://preprod.entourage.social/app/users/3445">@</a>. Voici une mention \n') }
    end
  end
end
