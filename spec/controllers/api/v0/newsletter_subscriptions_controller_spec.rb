require 'rails_helper'

RSpec.describe Api::V0::NewsletterSubscriptionsController, :type => :controller, skip: true do

  describe "POST create" do

    before(:each) do
      stub_request(:post, "https://us8.api.mailchimp.com/2.0/lists/subscribe.json").
          to_return(:status => 200, :body => "", :headers => {})
    end

    context "with correct parameters" do
      let(:newsletter_subscription_attributes) { attributes_for(:newsletter_subscription) }

      it "renders 201" do
        post 'create', newsletter_subscription: {email: newsletter_subscription_attributes[:email], active: newsletter_subscription_attributes[:active]}, format: :json
        expect(response.status).to eq(201)
      end

      it "creates new subscription" do
        newsletter_subscription_count = NewsletterSubscription.count
        post 'create', newsletter_subscription: {email: newsletter_subscription_attributes[:email], active: newsletter_subscription_attributes[:active]}, format: :json
        expect(NewsletterSubscription.count).to be(newsletter_subscription_count + 1)
      end

      it "renders newsletter subscription" do
        post 'create', newsletter_subscription: {email: newsletter_subscription_attributes[:email], active: newsletter_subscription_attributes[:active]}, format: :json
        expect(JSON.parse(response.body)).to eq("newsletter_subscription"=>{"email"=>newsletter_subscription_attributes[:email], "active"=>true})
      end

    end

    context "with incorrect parameters" do

      it "renders 400" do
        post 'create', newsletter_subscription: {not_email_param: "subscriber@newsletter.com", not_active_param: true}, :format => :json
        expect(response.status).to eq(400)
      end
    end
  end
end
