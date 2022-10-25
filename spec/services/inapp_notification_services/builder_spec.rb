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
    let(:subject) { InappNotificationServices::Builder.new(user).instanciate(instance: instance, instance_id: instance_id) }

    let(:neighborhood) { create(:neighborhood) }
    let(:instance) { :neighborhood }
    let(:instance_id) { neighborhood.id }

    before { InappNotificationServices::Builder.any_instance.stub(:accepted_configuration?) { acceptance } }

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

      context 'instanciation' do
        before { subject }

        it { expect(subject).to eq(true) }
      end

      context 'record is created' do
        it { expect { subject }.to change { InappNotification.count }.by(1) }
      end
    end
  end
end
