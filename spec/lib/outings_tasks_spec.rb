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

    before { outing.moderation.update_attribute(:moderated_at, moderated_at) }

    context 'correct params and moderated' do
      it { expect(subject).to include(outing.id) }
    end

    context 'correct params but not moderated' do
      before { outing.moderation.update_attribute(:moderated_at, nil) }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'correct params but no moderation' do
      before { outing.moderation.destroy }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'not admin creator' do
      before { user.update(admin: false, targeting_profile: :asks_for_help) }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'not admin creator but team' do
      before { user.update(admin: false, targeting_profile: :team) }

      it { expect(subject).to include(outing.id) }
    end

    context 'already notified' do
      let(:notification_sent_at) { Time.zone.now }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'in the past' do
      let(:starts_at) { 1.minute.ago }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'inside of upcoming delay' do
      let(:starts_at) { OutingTasks::POST_UPCOMING_DELAY.from_now - 1.hour }

      it { expect(subject).to include(outing.id) }
    end

    context 'outside of upcoming delay' do
      let(:starts_at) { OutingTasks::POST_UPCOMING_DELAY.from_now + 1.hour }

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
      it { expect(outing.chat_messages.first.content).to eq(I18n.t("outings.tasks.reminder_content")) }
    end

    context 'outing properties' do
      before { subject }

      it { expect(outing.reload.notification_sent_at).not_to be_nil }
    end
  end

  describe 'organisator_outings_in_days' do
    let(:user) { create :public_user}
    let(:starts_at) { 7.days.from_now.change(hour: 12) }

    before { outing }
    subject { OutingTasks.organisator_outings_in_days(7).pluck(:id) }

    context 'admin creator' do
      let(:user) { create :admin_user }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'public user creator' do
      it { expect(subject).to include(outing.id) }
    end

    context 'in the past' do
      let(:starts_at) { 1.minute.ago }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'outside of upcoming delay' do
      let(:starts_at) { 7.days.from_now.change(hour: 12) - 1.day }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'online' do
      let(:online) { true }

      it { expect(subject).not_to include(outing.id) }
    end
  end

  describe 'send_private_message_7_days_before' do
    let(:user) { create :public_user}
    let(:starts_at) { 7.days.from_now.change(hour: 12) }

    before { outing }
    before { ModerationServices.stub(:moderator_for_user) { create :public_user } }

    subject { OutingTasks.send_private_message_7_days_before }

    context 'creates a chat_message' do
      it { expect { subject }.to change { ChatMessage.count }.by(1) }

      context 'content' do
        before { subject }

        it { expect(ChatMessage.last.content).to match(/ton événement approche/) }
      end
    end
  end

  describe 'send_private_message_1_day_before' do
    let(:user) { create :public_user}
    let(:starts_at) { 1.days.from_now.change(hour: 12) }

    before { outing }
    before { ModerationServices.stub(:moderator_for_user) { create :public_user } }

    subject { OutingTasks.send_private_message_1_day_before }

    context 'creates a chat_message' do
      it { expect { subject }.to change { ChatMessage.count }.by(1) }

      context 'content' do
        before { subject }

        it { expect(ChatMessage.last.content).to match(/a lieu demain/) }
      end
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

  describe 'upcoming_outings_for_user' do
    subject { OutingTasks.upcoming_outings_for_user(user).pluck(:id) }

    before { OutingsServices::Finder.any_instance.stub(:find_all).and_return(Outing.all) }
    before { outing.moderation.update_attribute(:moderated_at, moderated_at) }

    # include
    context 'correct params and moderated' do
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

    context 'inside of upcoming delay' do
      let(:starts_at) { OutingTasks::EMAIL_UPCOMING_DELAY.from_now - 1.hour }

      it { expect(subject).to include(outing.id) }
    end

    # not include
    context 'not admin creator nor team' do
      before { user.update(admin: false, targeting_profile: :asks_for_help) }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'in the past' do
      let(:starts_at) { 1.minute.ago }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'outside of upcoming delay' do
      let(:starts_at) { OutingTasks::EMAIL_UPCOMING_DELAY.from_now + 1.hour }

      it { expect(subject).not_to include(outing.id) }
    end

    context 'online' do
      let(:online) { true }

      it { expect(subject).to include(outing.id) }
    end
  end
end
