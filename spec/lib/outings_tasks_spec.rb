require 'rails_helper'
require 'tasks/outing_tasks'

describe OutingTasks do
  let(:user) { create :admin_user }
  let(:status) { :open }
  let(:notification_sent_at) { nil }
  let(:starts_at) { 1.hour.from_now }

  let(:outing) { create :outing,
    status: status,
    notification_sent_at: notification_sent_at,
    user: user,
    metadata: { starts_at: starts_at }
  }

  describe "upcoming_outings" do
    subject { OutingTasks.upcoming_outings.pluck(:id) }

    before { outing }

    context "correct params" do
      it { expect(subject).to include(outing.id) }
    end

    context "not admin creator" do
      let(:user) { create :public_user }

      it { expect(subject).not_to include(outing.id) }
    end

    context "already notified" do
      let(:notification_sent_at) { Time.zone.now }

      it { expect(subject).not_to include(outing.id) }
    end

    context "in the past" do
      let(:starts_at) { 1.minute.ago }

      it { expect(subject).not_to include(outing.id) }
    end

    context "outside of upcoming delay" do
      let(:starts_at) { OutingTasks::UPCOMING_DELAY + 1.hour }

      it { expect(subject).not_to include(outing.id) }
    end
  end

  describe "send_post_to_upcoming" do
    subject { OutingTasks.send_post_to_upcoming }

    before { outing }

    context "creates a chat_message" do
      it { expect { subject }.to change { ChatMessage.count }.by(1) }
    end

    context "chat_message properties" do
      before { subject }

      it { expect(outing.chat_messages.count).to eq(1) }
      it { expect(outing.chat_messages.first.content).to eq(OutingTasks::REMINDER_CONTENT) }
    end

    context "outing properties" do
      before { subject }

      it { expect(outing.reload.notification_sent_at).not_to be_nil }
    end
  end
end
