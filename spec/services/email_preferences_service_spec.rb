require 'rails_helper'

describe EmailPreferencesService do
  let(:service) { EmailPreferencesService }
  before do
    service.stub(:enable_callback?) { true }
    allow(MailchimpService).to receive(:update)
    allow(MailchimpService).to receive(:add_or_update)
  end

  context "when a user unsubscribes" do
    let(:user) { create :public_user, accepts_emails: true }
    it do
      user.update(accepts_emails: false)

      expect(MailchimpService)
        .to have_received(:add_or_update)
        .with(
          :newsletter, user.email,
          status: :unsubscribed,
          status_if_new: :unsubscribed,
          unsubscribe_reason: "via le site"
        )
    end
  end

  context "when a user subscribes" do
    let(:user) { create :public_user, accepts_emails: false }
    it do
      user.update(accepts_emails: true)

      expect(MailchimpService)
        .to have_received(:update)
        .with(
          :newsletter, user.email,
          status: :subscribed
        )
    end
  end
end
