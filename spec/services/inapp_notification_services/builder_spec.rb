require 'rails_helper'

describe InappNotificationServices::Builder do
  let(:user) { FactoryBot.create(:pro_user) }

  describe 'skip_obsolete_notifications' do
    let(:subject) { InappNotificationServices::Builder.new(user).skip_obsolete_notifications }

    context 'skip notifications belonging to user' do
      let!(:inapp_notification) { create(:inapp_notification, :obsolete, user: user ) }

      before { subject }

      it { expect(inapp_notification.reload.skipped_at).to be_a(ActiveSupport::TimeWithZone) }
    end

    context 'does not skip notifications not obsolete' do
      let!(:inapp_notification) { create(:inapp_notification, user: user, created_at: InappNotificationServices::Builder::OBSOLETE_PERIOD + 1.hour) }

      before { subject }

      it { expect(inapp_notification.reload.skipped_at).to be_nil }
    end

    context 'does not skip completed notifications' do
      let!(:inapp_notification) { create(:inapp_notification, :obsolete, user: user, completed_at: Time.now) }

      before { subject }

      it { expect(inapp_notification.reload.skipped_at).to be_nil }
    end

    context 'does not skip notifications not belonging to user' do
      let!(:inapp_notification) { create(:inapp_notification, :obsolete) }

      before { subject }

      it { expect(inapp_notification.reload.skipped_at).to be_nil }
    end
  end

  describe 'instanciate' do
    let(:neighborhood) { create(:neighborhood) }
    let(:context) { :entourage_on_create }
    let(:instance) { :neighborhood }
    let(:instance_id) { neighborhood.id }
    let(:content) { "foo" }

    let(:subject) { InappNotificationServices::Builder.new(user).instanciate(context: context, instance: instance, instance_id: instance_id, referent: instance, referent_id: instance_id, content: content) }

    # before { InappNotificationServices::Builder.any_instance.stub(:accepted_configuration?) { acceptance } }
    before { NotificationPermission.stub(:notify_inapp?) { acceptance } }

    describe 'configuration not accepting instance' do
      let(:acceptance) { false }

      context 'no instanciation' do
        before { subject }

        it { expect(subject).to eq(nil) }
      end

      context 'no record' do
        it { expect { subject }.not_to change { InappNotification.count } }
      end
    end

    describe 'configuration accept instance' do
      let(:acceptance) { true }

      describe 'instanciation' do
        it { expect(subject).to eq(true) }
      end

      describe 'record is created' do
        it { expect { subject }.to change { InappNotification.count }.by(1) }
      end

      describe 'record already exists and has not been completed' do
        let!(:inapp_notification) { create(:inapp_notification, user: user, context: context, content: "bar") }
        let(:instance) { inapp_notification.instance }
        let(:instance_id) { inapp_notification.instance_id }

        describe 'record is not created' do
          it { expect { subject }.to change { InappNotification.count }.by(0) }
        end

        describe 'record is not updated' do
          before { subject }

          it { expect(InappNotification.where(user: user).count).to eq(1) }
          it { expect(InappNotification.where(user: user).first.content).to eq("bar") }
        end
      end

      describe 'record already exists and has been completed' do
        let!(:inapp_notification) { create(:inapp_notification, user: user, context: context, content: "bar", completed_at: Time.now) }
        let(:instance) { inapp_notification.instance }
        let(:instance_id) { inapp_notification.instance_id }

        describe 'record is created' do
          it { expect { subject }.to change { InappNotification.count }.by(1) }
        end

        describe 'record is updated' do
          before { subject }

          it { expect(InappNotification.where(user: user).count).to eq(2) }
          it { expect(InappNotification.where(user: user).first.content).to eq("foo") }
        end
      end

      describe 'record does not exist for this user' do
        let!(:inapp_notification) { create(:inapp_notification, context: context, content: "bar", completed_at: Time.now) }
        let(:instance) { inapp_notification.instance }
        let(:instance_id) { inapp_notification.instance_id }

        describe 'record is created' do
          it { expect { subject }.to change { InappNotification.count }.by(1) }
        end

        describe 'record is updated' do
          before { subject }

          it { expect(InappNotification.where(user: inapp_notification.user).count).to eq(1) }
          it { expect(InappNotification.where(user: user).count).to eq(1) }
          it { expect(InappNotification.where(user: user).first.content).to eq("foo") }
        end
      end
    end
  end
end
