require 'rails_helper'

describe EmailPreferencesService do
  let(:service) { EmailPreferencesService }
  let!(:category) { create :email_category, name: :newsletter rescue PG::UniqueViolation }

  before do
    service.stub(:enable_mailchimp_callback?) { true }
    allow(MailchimpService).to receive(:update)
    allow(MailchimpService).to receive(:add_or_update)
  end

  context "when a user unsubscribes" do
    let(:user) { create :public_user }
    it do
      EmailPreferencesService.update_subscription(category: :newsletter, subscribed: false, user: user)

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
    let(:user) { create :public_user }
    it do
      EmailPreferencesService.update_subscription(category: :newsletter, subscribed: true, user: user)

      expect(MailchimpService)
        .to have_received(:update)
        .with(
          :newsletter, user.email,
          status: :subscribed
        )
    end
  end
end
