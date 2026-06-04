require 'rails_helper'

describe Onboarding::UserEventsTracking do
  let!(:user) { create(:public_user) }

  describe 'welcome_watched!' do
    let(:subject) { user.welcome_watched! }

    it { subject }

    after { expect(Event.find_by(user: user, name: "onboarding.resource.welcome_watched").present?).to be(true) }
  end
end
