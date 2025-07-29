require 'rails_helper'
require 'tasks/outing_tasks'

describe OutingTasks do
  let(:user) { create :admin_user, partner: create(:partner, staff: true) }
  let(:status) { :open }
  let(:online) { false }
  let(:notification_sent_at) { nil }
  let(:starts_at) { 1.hour.from_now }
  let(:moderated_at) { Time.zone.now }

  let(:outing) { create :outing,
    country: 'FR',
    postal_code: '44240',
    status: status,
    online: online,
    notification_sent_at: notification_sent_at,
    user: user,
    metadata: { starts_at: starts_at }
  }

  describe 'upcoming_outings' do
    subject { OutingTasks.upcoming_outings.pluck(:id) }

    # include
    context 'correct params and moderated' do
      before { outing.moderation.update_attribute(:moderated_at, moderated_at) }

      it { expect(subject).to include(outing.id) }
    end

    context 'correct params but not moderated' do
      before { outing.moderation.update_attribute(:moderated_at, nil) }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'correct params but not exists' do
      before { outing.moderation.destroy }

      it { expect(subject).not_to include(outing.id) }
    end

    # not include
    context 'not admin creator nor team' do
      let(:user) { create :partner_user }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'already notified' do
      let(:notification_sent_at) { Time.zone.now }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'in the past' do
      let(:starts_at) { 1.minute.ago }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'outside of upcoming delay' do
      let(:starts_at) { OutingTasks::POST_UPCOMING_DELAY + 1.hour }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'online' do
      let(:online) { true }

      it { expect(subject).not_to include(outing.id) }
    end
  end

  describe 'send_post_to_upcoming' do
    subject { OutingTasks.send_post_to_upcoming }

    before { outing.moderation.update_attribute(:moderated_at, moderated_at) }

    context 'creates a chat_message' do
      it { expect { subject }.to change { ChatMessage.count }.by(1) }
    end

    context 'chat_message properties' do
      before { subject }

      it { expect(outing.chat_messages.count).to eq(1) }
      it { expect(outing.chat_messages.first.content).to eq(OutingTasks::REMINDER_CONTENT) }
    end

    context 'outing properties' do
      before { subject }

      it { expect(outing.reload.notification_sent_at).not_to be_nil }
    end
  end

  describe "send_email_as_reminder" do
    let(:starts_at) { Time.zone.now.tomorrow.change(hour: 12) }
    let(:outing_ref) { Outing.find(outing.id) } # forces class Outing rather than Entourage

    let(:member) { create(:public_user) }
    let!(:join_request) { create(:join_request, user: member, joinable: outing_ref, status: :accepted) }

    subject { OutingTasks.send_email_as_reminder }

    before { outing_ref.moderation.update_attribute(:moderated_at, moderated_at) }

    context "calls GroupMailer" do
      # it { expect_any_instance_of(GroupMailer).to receive(:event_participation_reminder) }
      it { expect_any_instance_of(GroupMailer).to receive(:event_participation_reminder).with(outing_ref, member) }

      after { subject }
    end
  end
end
