require 'rails_helper'
require 'rake'

describe 'onboarding_sequence:send_emails' do
  before(:all) do
    unless Rake::Task.task_defined?('onboarding_sequence:send_emails')
      Rake::Task.define_task(:environment)
      load Rails.root.join('lib/tasks/onboarding_sequence.rake')
    end
  end

  # the task runs once a day, at or after 8:30
  let(:now) { Time.zone.now.change(hour: 9, min: 0) }

  around { |example| Timecop.freeze(now) { example.run } }

  let!(:welcome_video) { create :resource, tag: :welcome }
  let!(:user) { create :offer_help_user, created_at: 5.days.ago, first_sign_in_at: 5.days.ago }

  subject do
    task = Rake::Task['onboarding_sequence:send_emails']
    task.reenable
    task.invoke
  end

  describe 'unseen video reminder, 5 days after the registration' do
    it 'is sent' do
      mail = double('mail')
      expect(MemberMailer).to receive(:unseen_video_day_5).with(user).and_return(mail)
      expect(mail).to receive(:deliver_later)

      subject
    end

    context 'when the member skipped the video step' do
      before { user.welcome_watched_skipped! }

      it 'is not sent' do
        expect(MemberMailer).not_to receive(:unseen_video_day_5)

        subject
      end
    end

    context 'when the member skipped another step' do
      before { user.neighborhood_national_joined_skipped! }

      it 'is sent' do
        expect(MemberMailer).to receive(:unseen_video_day_5).with(user).and_return(double(deliver_later: true))

        subject
      end
    end

    context 'when the member hid the journey' do
      before { user.hide_onboarding_journey! }

      it 'is not sent' do
        expect(MemberMailer).not_to receive(:unseen_video_day_5)

        subject
      end
    end

    context 'when the member already watched the video' do
      before { allow_any_instance_of(User).to receive(:has_watched_resource?).with(welcome_video.id).and_return(true) }

      it 'is not sent' do
        expect(MemberMailer).not_to receive(:unseen_video_day_5)

        subject
      end
    end
  end
end
