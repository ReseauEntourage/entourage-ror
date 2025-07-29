require 'rails_helper'

describe EmailDeliveryHooks do
  before(:all) do
    @mailer = Class.new(ActionMailer::Base) do
      include EmailDeliveryHooks::Concern
      default from: 'from@example.com',
              to:   'to@example.com'

      def untracked_email
        mail { nil }
      end

      def timestamp_tracked_email user_id
        track_delivery user_id: user_id, campaign: :tracked_email
        mail { nil }
      end

      def fully_tracked_email user_id
        track_delivery user_id: user_id, campaign: :tracked_email, detailed: true
        mail { nil }
      end

      def unique_email user_id
        track_delivery user_id: user_id, campaign: :unique_email,
                       deliver_only_once: true
        mail { nil }
      end

      def sampled_email
        collect_samples rate: 0.02, address: 'samples@example.com'
        mail { nil }
      end
    end
  end

  let(:user) { create :public_user }

  describe 'email tracking' do
    describe 'sending timestamp_tracked_email' do
      subject { -> { @mailer.timestamp_tracked_email(user.id).deliver_now } }

      it "doesn't create an EmailDelivery" do
        expect { subject.call }.not_to change { EmailDelivery.count }
      end

      it "updates the user's last_email_sent_at" do
        # rounding seconds to ignore differences nanoseconds precision in db
        time = Time.at(Time.now.to_i)
        expect { Timecop.freeze(time) { subject.call } }
        .to change { user.reload.last_email_sent_at }
        .to(time)
      end
    end

    describe 'sending fully_tracked_email' do
      subject { -> { @mailer.fully_tracked_email(user.id).deliver_now } }

      it "updates the user's last_email_sent_at" do
        # rounding seconds to ignore differences nanoseconds precision in db
        time = Time.at(Time.now.to_i)
        expect { Timecop.freeze(time) { subject.call } }
        .to change { user.reload.last_email_sent_at }
        .to(time)
      end

      it 'creates a correct EmailDelivery' do
        # rounding seconds to ignore differences nanoseconds precision in db
        time = Time.at(Time.now.to_i)
        Timecop.freeze(time) { subject.call }

        expect(EmailDelivery.last&.attributes&.symbolize_keys).to include(
          user_id: user.id,
          sent_at: time
        )
        expect(EmailDelivery.last&.campaign&.name).to eq 'tracked_email'
      end
    end

    describe 'sending 2 unique_email' do
      let(:subject) {
        @mailer.unique_email(user.id).deliver_now
        @mailer.unique_email(user.id).deliver_now
      }
      it 'delivers only one email' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by 1
      end

      it 'creates only one EmailDelivery' do
        expect { subject }.to change { EmailDelivery.count }.by 1
      end
    end

    describe 'sending untracked_email' do
      let(:subject) { @mailer.untracked_email.deliver_now }
      it 'sends the email (no interference)' do
        expect { subject }.to change { ActionMailer::Base.deliveries.count }.by 1
      end
    end
  end

  describe 'email sampling' do
    before { EmailDeliveryHooks.stub(:sample) { sample } }
    subject { @mailer.sampled_email.deliver_now.bcc }

    context 'when the message is sampled' do
      let(:sample) { true }
      it do
        expect(EmailDeliveryHooks)
          .to receive(:sample).with(rate: 0.02, key: 'to@example.com')
        subject
      end
      it { expect(subject).to include 'samples@example.com' }
    end

    context 'when the message is not sampled' do
      let(:sample) { false }
      it { expect(subject).to be nil }
    end
  end
end
