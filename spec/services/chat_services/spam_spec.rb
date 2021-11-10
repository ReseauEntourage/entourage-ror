require 'rails_helper'

describe ChatServices::Spam do
  let(:user) { FactoryBot.create(:public_user) }
  let(:conversations) { FactoryBot.create_list(:conversation, 6, user: user) }

  describe 'spams' do
    context 'same messages' do
      let(:chat_messages) {
        conversations.map do |conversation|
          FactoryBot.create(:chat_message, content: 'This is a spam message.', messageable: conversation, user: user)
        end
      }

      it { expect(chat_messages.first.spams.length).to be(0) }
      it { expect(chat_messages.last.spams.length).to be(5) }
    end

    context 'different messages' do
      let(:contents) { [
        'Lorem ipsum dolor sit amet',
        'consectetur adipiscing elit',
        'sed do eiusmod tempor incididunt ut labore',
        'et dolore magna aliqua',
        'Ut enim ad minim veniam',
        'quis nostrud exercitation ullamco'
      ]}
      let(:chat_messages) {
        conversations.zip(contents).map do |conversation, content|
          FactoryBot.create(:chat_message, content: content, messageable: conversation, user: user)
        end
      }

      it { expect(chat_messages.first.spams.length).to be(0) }
      it { expect(chat_messages.last.spams.length).to be(0) }
    end

    context 'similar messages' do
      let(:contents) { [
        'This is a spamm message',
        'This is a spam mesage',
        'This is a spamed message',
        'This is a spammed message',
        'This is a spam messages',
        'This is a spam message'
      ]}
      let(:chat_messages) {
        conversations.zip(contents).map do |conversation, content|
          FactoryBot.create(:chat_message, content: content, messageable: conversation, user: user)
        end
      }

      it { expect(chat_messages.first.spams.length).to be(0) }
      it { expect(chat_messages.last.spams.length).to be(5) }
    end

    context 'same messages but in same conversation' do
      let(:chat_messages) {
        FactoryBot.create_list(:chat_message, 6, content: 'This is a spam message.', messageable: conversations.first, user: user)
      }

      it { expect(chat_messages.first.spams.length).to be(0) }
      it { expect(chat_messages.last.spams.length).to be(1) }
    end
  end

  describe 'check_spams!' do
    describe 'spams exists' do
      let(:chat_messages) {
        conversations.map do |conversation|
          FactoryBot.create(:chat_message, content: 'This is a spam message.', messageable: conversation, user: user)
        end
      }

      let(:chat_message) { FactoryBot.create(:chat_message, content: chat_messages.last.content, messageable: chat_messages.last.messageable, user: user) }

      before { SlackServices::SignalSpam.any_instance.stub(:notify) { nil } }

      context 'no spam has been reported' do
        before { expect(UserHistory).to receive(:create) }

        it { chat_message.check_spam! }
      end

      context 'spam has been reported' do
        let!(:user_history) { FactoryBot.create(:user_history, user: user, metadata: {
          messageable_id: chat_messages.last.messageable_id,
          messageable_type: 'Entourage'
        })}

        before { expect(UserHistory).not_to receive(:create) }

        it { chat_message.check_spam! }
      end
    end
  end
end
