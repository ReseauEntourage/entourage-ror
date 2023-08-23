require 'rails_helper'

describe MailjetMailer do
  let(:category) { create :email_category }
  let(:user) { create :public_user }
  let(:mail) { MailjetMailer.mailjet_email(**{to: user, template_id: 1234, campaign_name: :test_campaign}.merge(mail_options)) }
  let(:mail_options) { {} }

  describe "unsubscribe" do
    let(:mail_options) { {unsubscribe_category: category.name} }
    let(:unsubscribe_url) { EmailPreferencesService.update_url(category: category.name, accepts_emails: false, user: user) }
    let(:mailjet_vars) { JSON.parse(mail['X-MJ-Vars'].value) }
    let(:mailjet_payload) { JSON.parse(mail['X-MJ-EventPayload'].value) }

    it "sets the unsubscribe_url variable" do
      expect(mailjet_vars['unsubscribe_url']).to eq unsubscribe_url
    end

    it "sets the unsubscribe_category variable in the payload" do
      expect(mailjet_payload['unsubscribe_category']).to eq category.name
    end

    it "drops the email if the user is unsubscribed from the category" do
      EmailPreferencesService.update_subscription(user: user, category: category.name, subscribed: false)
      expect(mail.message).to be_a ActionMailer::Base::NullMail
    end
  end

  describe "delivery_tracking" do
    context "when deliver_only_once is not specified" do
      it "calls track_delivery" do
        expect_any_instance_of(MailjetMailer)
          .to receive(:track_delivery)
          .with(
            user_id: user.id,
            campaign: :test_campaign,
            deliver_only_once: false,
            detailed: true
          )
        mail.message
      end
    end

    context "when deliver_only_once is true" do
      let(:mail_options) { { deliver_only_once: true } }
      it "calls track_delivery with deliver_only_once: true" do
        expect_any_instance_of(MailjetMailer)
          .to receive(:track_delivery)
          .with(
            user_id: user.id,
            campaign: :test_campaign,
            deliver_only_once: true,
            detailed: true
          )
        mail.message
      end
    end
  end
end
