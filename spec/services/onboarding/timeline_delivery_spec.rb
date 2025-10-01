require 'rails_helper'

describe Onboarding::TimelineDelivery do
  let(:sunday) { Time.parse('01/01/2023 12:00:00') }
  let(:monday) { Time.parse('02/01/2023 12:00:00') }

  describe 'deliver_welcome_message' do
    let(:subject) { Onboarding::TimelineDelivery.deliver_welcome }

    before { Timecop.freeze(monday) }

    after { subject }

    context 'no user' do
      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register less than one hour' do
      let!(:user) { create(:public_user, first_sign_in_at: 30.minutes.ago) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register more than hour ago' do
      let!(:user) { create(:public_user, first_sign_in_at: 80.minutes.ago) }

      it { expect_any_instance_of(Onboarding::Timeliner).to receive(:run) }
    end

    context 'user having register more than hour ago but already has received run' do
      let!(:user) { create(:public_user, first_sign_in_at: 80.minutes.ago) }

      before { Event.track('onboarding.push_notifications.welcome.sent', user_id: user.id) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register more than hour ago but it is sunday' do
      let!(:user) { create(:public_user, first_sign_in_at: 80.minutes.ago) }

      before { Timecop.freeze(sunday) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end
  end

  describe 'deliver_on' do
    let(:subject) { Onboarding::TimelineDelivery.deliver_on(5) }

    before { Timecop.freeze(monday) }

    after { subject }

    context 'no user' do
      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register less than 5 days ago' do
      let!(:user) { create(:public_user, first_sign_in_at: 4.days.ago) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register exactly 5 days ago' do
      let!(:user) { create(:public_user, first_sign_in_at: 5.days.ago) }

      it { expect_any_instance_of(Onboarding::Timeliner).to receive(:run) }
    end

    context 'user having register more than 5 days ago' do
      let!(:user) { create(:public_user, first_sign_in_at: 6.days.ago) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end

    context 'user having register more than 5 days ago but it is sunday' do
      let!(:user) { create(:public_user, first_sign_in_at: 5.days.ago) }

      before { Timecop.freeze(sunday) }

      it { expect_any_instance_of(Onboarding::Timeliner).not_to receive(:run) }
    end
  end
end
