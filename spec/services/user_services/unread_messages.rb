require 'rails_helper'

describe UserServices::UnreadMessages do
  describe 'unread_conversations' do
    let(:subject) { UserServices::UnreadMessages.new(user: user).unread_conversations }

    let(:user) { create(:public_user) }
    let!(:join_request) { create(:join_request, joinable: joinable, user: user, status: :accepted, last_message_read: last_message_read) }
    let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.ago, messageable: joinable) }

    context "with unread on a conversation, old last_message_read" do
      let(:joinable) { create :conversation }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([joinable.id]) }
    end

    context "with unread on a conversation, no last_message_read" do
      let(:joinable) { create :conversation }
      let(:last_message_read) { nil }

      it { expect(subject).to match_array([joinable.id]) }
    end

    context "with no unread on a conversation" do
      let(:joinable) { create :conversation }
      let(:last_message_read) { Time.now }

      it { expect(subject).to match_array([]) }
    end

    context "with unread on a outing is not relevant" do
      let(:joinable) { create :outing }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([]) }
    end

    context "with unread on a entourage is not relevant" do
      let(:joinable) { create :entourage }
      let(:last_message_read) { 1.day.ago }

      it { expect(subject).to match_array([]) }
    end
  end

  describe 'number_of_unread_for_joinable_types' do
    let(:subject) { UserServices::UnreadMessages.new(user: user).number_of_unread_for_joinable_types(types) }

    let(:user) { create(:public_user) }
    let!(:joinable) { create :neighborhood }
    let!(:join_request) { create(:join_request, joinable: joinable, user: user, status: :accepted, last_message_read: 1.day.ago) }
    let!(:chat_message) { FactoryBot.create(:chat_message, created_at: 1.minute.ago, messageable: joinable) }

    context "on expected types" do
      let(:types) { :Neighborhood }
      it { expect(subject).to eq(1) }
    end

    context "on different types" do
      let(:types) { :Smalltalk }
      it { expect(subject).to eq(0) }
    end
  end
end
