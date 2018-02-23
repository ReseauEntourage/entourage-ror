require 'rails_helper'

RSpec.describe 'ActionMailer::Base#rescue_from' do
  class ExampleMailer < ActionMailer::Base
    rescue_from Net::ProtocolError, with: :handle_delivery_error

    def handle_delivery_error(exception); end

    def example_email; end
  end

  let(:delivery) { ExampleMailer.example_email }
  let(:delivery_exception) { Net::SMTPServerBusy.new }

  before do
    allow_any_instance_of(Mail::TestMailer)
      .to receive(:deliver!)
      .and_raise delivery_exception
  end

  it "rescues the exception and passes it to the handler" do
    allow_any_instance_of(ExampleMailer)
      .to receive(:handle_delivery_error) do |_, exception|
        expect(exception).to be delivery_exception
      end
    expect { delivery.deliver_now }.not_to raise_error
  end
end
