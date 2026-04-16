require 'rails_helper'

describe Onboarding::Timeliner do
  let!(:user) { create(:public_user) }
  let(:subject) { Onboarding::Timeliner.new(user.id, verb).run }

  let!(:neighborhood) { create(:neighborhood) }

  before { User.any_instance.stub(:default_neighborhood).and_return(neighborhood) }

  describe 'offer_help_on_h1_after_registration' do
    let(:verb) { :h1_after_registration }

    after { subject }

    it { expect_any_instance_of(PushNotificationService).to receive(:send_notification).with(
      nil,
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.h1.title'),
      Onboarding::Timeliner::I18nStruct.new(i18n: 'timeliner.h1.offer'),
      [user], :resources, nil,
      { instance: :resources, stage: :h1 }
    ) }
  end
end
