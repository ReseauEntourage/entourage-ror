require 'rails_helper'

RSpec.describe UnseenResourceWelcomeJob do
  let(:user) { create :public_user, goal: 'offer_help' }
  let!(:welcome_video) { create :resource, tag: :welcome }

  subject { described_class.new.perform(user.id) }

  before { allow_any_instance_of(PushNotificationService).to receive(:send_notification) }

  describe '#perform' do
    it 'sends a push notification' do
      expect_any_instance_of(PushNotificationService).to receive(:send_notification)
      subject
    end

    it 'records the event' do
      expect { subject }.to change { Event.where(name: UnseenResourceWelcomeJob::EVENT_NAME, user_id: user.id).count }.by(1)
    end

    context 'when user is not offer_help or ask_for_help' do
      let(:user) { create :public_user, goal: 'organization' }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when user has already watched the video' do
      before { UsersResource.create!(user: user, resource: welcome_video, watched: true) }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when the member skipped the video step' do
      before { user.welcome_watched_skipped! }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when the member skipped another step' do
      before { user.papotages_joined_skipped! }

      it 'sends a push notification' do
        expect_any_instance_of(PushNotificationService).to receive(:send_notification)
        subject
      end
    end

    context 'when the member hid the journey' do
      before { user.hide_onboarding_journey! }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when the journey is over' do
      before { user.update_columns(created_at: 20.days.ago, first_sign_in_at: 20.days.ago) }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when notification was already sent' do
      before { Event.track(UnseenResourceWelcomeJob::EVENT_NAME, user_id: user.id) }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when welcome video does not exist' do
      before { welcome_video.destroy }

      it 'does not send' do
        expect_any_instance_of(PushNotificationService).not_to receive(:send_notification)
        subject
      end
    end

    context 'when user does not exist' do
      it 'does not raise' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end
    end
  end
end
