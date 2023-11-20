require 'rails_helper'

RSpec.describe Api::V1::NewsletterSubscriptionsController, :type => :controller do
  describe "GET show" do
    before(:each) do
      contact = double
      contact.stub(:attributes) {{ email: "foo@bar.fr" }}
      Mailjet::Contact.stub(:find).and_return(contact)
    end

    before { get 'show', params: { email: "foo@bar.fr" } }

    it { expect(response.status).to eq(200) }
    it { expect(response.body).to eq({ contact: { email: "foo@bar.fr" }}.to_json) }
  end

  describe "POST create" do
    before(:each) do
      stub_request(:post, "https://api.mailjet.com/v3/REST/contactslist/2822632/managecontact").to_return(
        :status => 200,
        :body => {
          count: 1,
          data: {
            name: "foo",
            properties: {
              :newsletter_entourage => true,
              :antenne_entourage => "NANTES",
              :profil_entourage => "PARTICULIER"
            },
            action: "addnoforce",
            email: "foo@bar.fr"
          }
        }.to_json,
        :headers => {}
      )
    end

    let(:params) {{ newsletter_subscription: {
      email: "foo@bar.fr",
      zone: "NANTES",
      status: "PARTICULIER",
      active: "true"
    }, format: :json }}

    let(:request) { post 'create', params: params }

    context "with correct parameters" do
      before { request }

      it "renders 201" do
        expect(response.status).to eq(201)
        expect(JSON.parse(response.body)).to eq({ "message" => "Contact foo@bar.fr ajouté" })
      end

    end

    context "newsletter_subscription created" do
      it { expect { request }.to change { NewsletterSubscription.count }.by(1) }
    end

    context "with incorrect parameters" do
      let(:params) {{ newsletter_subscription: {
        not_email_param: "subscriber@newsletter.com",
        not_active_param: true
      }, :format => :json }}

      before { request }

      it { expect(response.status).to eq(400) }
    end
  end
end
