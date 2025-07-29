require 'rails_helper'

RSpec.describe Api::V1::ContactSubscriptionsController, type: :controller do
  describe "POST create" do
    let(:contact_subscription_attributes) { attributes_for(:contact_subscription) }

    let(:params) { {
      contact_subscription: {
        email: contact_subscription_attributes[:email],
        name: contact_subscription_attributes[:name],
        profile: contact_subscription_attributes[:profile],
        subject: contact_subscription_attributes[:subject],
        message: contact_subscription_attributes[:message]
      }
    }}

    let(:subject) { post :create, params: params }

    describe "with correct parameters" do
      context "renders correctly" do
        before { subject }

        it { expect(response.status).to eq(201) }
        it { expect(JSON.parse(response.body)).to eq("contact_subscription" => {
            "email" => contact_subscription_attributes[:email],
            "name" => contact_subscription_attributes[:name],
            "profile" => contact_subscription_attributes[:profile],
            "subject" => contact_subscription_attributes[:subject],
            "message" => contact_subscription_attributes[:message],
          })
        }
      end

      context "creates record" do
        it { expect { subject }.to change { ContactSubscription.count }.by(1) }
      end
    end

    describe "with incorrect parameters" do
      before { post 'create', params: { contact_subscription: {not_email_param: "subscriber@contact.com", not_active_param: true}, format: :json } }

      it { expect(response.status).to eq(400) }
    end
  end
end
