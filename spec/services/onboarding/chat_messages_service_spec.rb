require 'rails_helper'

describe Onboarding::ChatMessagesService, type: :service do
  describe '.deliver_welcome_message' do
    let(:run_time) { 1.week.from_now.monday.change(hour: 10, minute: rand(60)) }
    let(:onboarding_time) { run_time.advance(seconds: -rand(3.hours..4.hours)) }
    let!(:admin) { create :admin_user }
    let(:moderation_area) { create :moderation_area, moderator: admin, welcome_message_1_offer_help: "Bonjour {{first_name}}" }
    let!(:user) { create :public_user, first_name: nil }
    let(:address) { build :address }

    before do
      Onboarding::UserEventsTracking.stub(:enable_tracking?) { true }
      ModerationServices.stub(:moderation_area_for_user) { moderation_area }
      Timecop.freeze(onboarding_time) do
        user.update(first_name: 'lily-rose', goal: :offer_help)
        address.update(user: user)
      end
    end

    subject { Timecop.freeze(run_time) { Onboarding::ChatMessagesService.deliver_welcome_message } }

    it { expect { subject }.to change { ChatMessage.count }.by(2) }

    describe "event tracking" do
      def event
        Event.where(name: 'onboarding.chat_messages.welcome.sent', user_id: user.id).first
      end

      it { expect { subject }.to change { event.present? }.to true }
    end

    describe "chat message" do
      before { subject }
      let(:messages) { ChatMessage.last(2) }

      it { messages.each do |message|
        expect(message.user).to eq admin
      end }

      it { messages.each do |message|
        expect(message.messageable.members).to match_array [user, admin]
      end }

      it {
        expect(messages.first.content).to eq "Bonjour Lily-rose"
      }

      it {
        admin_join_request = messages.first.messageable.join_requests.find_by(user: admin)
        expect(admin_join_request).to be_archived
      }
    end

    describe 'outside of active hours' do
      let(:run_time) { 1.week.from_now.monday.change(hour: 7, minute: 59) }
      it { expect { subject }.not_to change { ChatMessage.count } }
    end

    describe 'outside of active days' do
      let(:run_time) { 1.week.from_now.sunday.change(hour: 14, minute: 25) }
      it { expect { subject }.not_to change { ChatMessage.count } }
    end

    describe 'user has already received the message' do
      before { Event.track('onboarding.chat_messages.welcome.sent', user_id: user.id) }
      it { expect { subject }.not_to change { ChatMessage.count } }
    end

    describe 'user has already been skipped' do
      before { Event.track('onboarding.chat_messages.welcome.skipped', user_id: user.id) }
      it { expect { subject }.not_to change { ChatMessage.count } }
    end

    describe 'user has already sent a message to the moderator' do
      let(:conversation) { create :conversation, participants: [user, admin] }
      before do
        create :chat_message, user: user, messageable: conversation
      end

      def event
        Event.where(name: 'onboarding.chat_messages.welcome.skipped', user_id: user.id).first
      end

      it { expect { subject }.not_to change { ChatMessage.count } }
      it { expect { subject }.to change { event.present? }.to true }
      it {
        admin_join_request = conversation.join_requests.find_by(user: admin)
        expect(admin_join_request).to_not be_archived
      }
    end
  end
end
