require 'rails_helper'

describe MailjetMailer do
  let(:category) { create :email_category }
  let(:user) { create :public_user }
  let(:mail) { MailjetMailer.mailjet_email({to: user, template_id: 1234, campaign_name: :test_campaign}.merge(mail_options)) }
  let(:mail_options) { {} }

  describe "unsubscribe" do
    let(:mail_options) { {unsubscribe_category: category.name} }
    let(:unsubscribe_url) { EmailPreferencesService.update_url(category: category.name, accepts_emails: false, user: user) }
    let(:mailjet_vars) { JSON.parse(mail['X-MJ-Vars'].value) }

    it "sets the unsubscribe_url variable" do
      expect(mailjet_vars['unsubscribe_url']).to eq unsubscribe_url
    end

    it "drops the email if the user is unsubscribed from the category" do
      EmailPreferencesService.update_subscription(user: user, category: category.name, subscribed: false)
      expect(mail.message).to be_a ActionMailer::Base::NullMail
    end
  end
end
