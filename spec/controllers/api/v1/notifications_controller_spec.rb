require 'rails_helper'

describe Api::V1::NotificationsController, :type => :controller do
  let!(:user) { create(:public_user) }

  describe "welcome" do
    after { put :welcome, params: { token: user.token } }

    it { expect_any_instance_of(Onboarding::Timeliner).to receive(:offer_help_on_h1_after_registration) }
  end

  describe "at_day" do
    after { put :at_day, params: { token: user.token, day: 2 } }

    it { expect_any_instance_of(Onboarding::Timeliner).to receive(:offer_help_on_j2_after_registration) }
  end
end
