require 'rails_helper'

describe MailchimpService, type: :service do
  let(:service) { MailchimpService }
  let(:config) do
    {
      'api_key' => 'SOME_API_KEY-SOME_DC',
      'lists' => {
        'some_list' => {
          'id' => 'SOME_LIST_ID',
          'interests' => {
            'some_interest' => 'SOME_INTEREST_ID'
          }
        }
      }
    }
  end
  before { service.stub(:config) { config } }

  let(:unformatted_email) { ' Some@Email.com' }
  let(:formatted_email) { 'some@email.com' }

  describe :request do
    let(:response) do
      {
        status: 200,
        headers: {'Content-Type'=>'application/json'},
        body: '{"EXAMPLE":"RESPONSE"}'
      }
    end

    before do
      stub_request(:any, %r{\A#{Regexp.escape('https://some_dc.api.mailchimp.com')}})
      .to_return(response)
    end

    subject do
      -> { service.request(:patch, "/SOME_PATH", {SOME: :BODY}) }
    end

    context "no api key" do
      let(:config) { {} }
      it { expect { subject.call }.to raise_error(MailchimpService::ConfigError, /API key/) }
    end

    context "valid parameters" do
      it "should make the expected request" do
        subject.call

        expect(a_request(
          :patch,
          'https://some_dc.api.mailchimp.com/3.0/SOME_PATH'
        ).with(
          basic_auth: ['', 'SOME_API_KEY-SOME_DC'],
          headers: {'Content-Type'=>'application/json'},
          body: '{"SOME":"BODY"}'
        )).to have_been_made.once
      end

      it "should return the expected reponse" do
        expect(subject.call).to eq('EXAMPLE'=>'RESPONSE')
      end
    end

    context "api error" do
      let(:response) { {status: 403, body: JSON.fast_generate(title: "Some Error")} }
      it { expect { subject.call }.to raise_error(MailchimpService::ApiError, /403 Some Error/) }
    end
  end

  describe "ApiError.for response" do
    let(:mock_response) { {status: response_body[:status], body: JSON.fast_generate(response_body)} }
    before { stub_request(:get, 'dummy.host').to_return(mock_response) }
    let(:response) { HTTParty.get('http://dummy.host') }
    subject { MailchimpService::ApiError.for(response) }

    context "when response is 404 Resource Not Found" do
      let(:response_body) { {status: 404, title: 'Resource Not Found' } }
      it { is_expected.to be_a MailchimpService::ResourceNotFound }
    end

    context "default API error" do
      let(:response_body) { {status: 400, title: 'Some Title' } }
      it { is_expected.to be_a MailchimpService::ApiError }
      it { expect(subject.title).to eq 'Some Title' }
      it { expect(subject.code).to eq 400 }
    end

    context "when the error has a `detail` field" do
      let(:response_body) { {status: 123, title: 'Other Title', detail: "Some detail" } }
      it { expect(subject.message).to match "Some detail" }
    end
  end

  describe :unsubscribe do
    subject do
      -> { service.unsubscribe(list: :some_list, email: unformatted_email) }
    end

    it do
      expect(service).to receive(:request)
      .with(
        :patch,
        "/lists/SOME_LIST_ID/members/#{Digest::MD5.hexdigest(formatted_email)}",
        {
          status: :unsubscribed
        }
      )

      subject.call
    end
  end

  describe :add_or_update do
    subject do
      service.add_or_update(:some_list, unformatted_email, some_key: :some_value)
    end

    it do
      expect(service).to receive(:request)
      .with(
        :put,
        "/lists/SOME_LIST_ID/members/#{Digest::MD5.hexdigest(formatted_email)}",
        {
          some_key: :some_value,
          email_address: formatted_email
        }
      )

      subject
    end
  end

  describe :update do
    it "makes the request when the email is whitelisted" do
      service.stub(:safety_mailer_whitelisted?) { true }
      expect(service).to receive(:request)
      service.update(:some_list, 'some@email.com')
    end
    it "drops the request when the email is not whitelisted" do
      service.stub(:safety_mailer_whitelisted?) { false }
      expect(service).not_to receive(:request)
      service.update(:some_list, 'some@email.com')
    end
  end

  describe :set_interest do
    subject do
      -> { service.set_interest(list: :some_list, email: unformatted_email, interest: :some_interest, value: true) }
    end

    it do
      expect(service).to receive(:request)
      .with(
        :patch,
        "/lists/SOME_LIST_ID/members/#{Digest::MD5.hexdigest(formatted_email)}",
        {
          interests: {
            'SOME_INTEREST_ID' => true
          }
        }
      )

      subject.call
    end
  end

  describe :safety_mailer_whitelisted? do
    context "when safety_mailer is in use" do
      around do |example|
        old_delivery_method = ActionMailer::Base.delivery_method
        ActionMailer::Base.delivery_method = :safety_mailer
        ActionMailer::Base.safety_mailer_settings = {
          allowed_matchers: [ /@entourage\.social\z/ ],
        }
        example.run
        ActionMailer::Base.deliveries.clear
        ActionMailer::Base.delivery_method = old_delivery_method
      end

      it { expect(service.safety_mailer_whitelisted?('contact@entourage.social')).to be true }
      it { expect(service.safety_mailer_whitelisted?('test@gmail.com')).to be false }
    end

    context "when safety_mailer is not in use" do
      it { expect(service.safety_mailer_whitelisted?('test@gmail.com')).to be true }
    end
  end
end
