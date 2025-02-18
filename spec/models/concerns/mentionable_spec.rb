require 'rails_helper'

RSpec.describe Mentionable, type: :module do
  let(:chat_message) { create(:chat_message, content: content) }
  
  describe Mentionable::MentionsStruct do
    subject { Mentionable::MentionsStruct.new(instance: chat_message) }

    context 'when content contains HTML' do
      let(:content) { '<p>Hello, <a href="https://preprod.entourage.social/app/users/123">User</a></p>' }

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
      let(:content) { '<p>Hello, <a href="https://preprod.entourage.social/app/users/123">John</a> and <a href="https://preprod.entourage.social/app/users/456">Jane</a></p>' }

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
end
