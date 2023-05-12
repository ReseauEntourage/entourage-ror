require 'rails_helper'

describe Onboarding::Timeliner do
  describe "offer_help_on_h1_after_registration" do
    let(:subject) { Onboarding::Timeliner.new(user.id, :h1_after_registration).run }

    let!(:user) { create(:public_user) }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
      nil,
      Onboarding::Timeliner::OFFER_H1,
      nil,
      [user],
      nil,
      nil,
      { welcome: true, stage: :h1, url: :resources }
    ) }
  end
end
