require 'rails_helper'

describe MailjetService do
  # verify async method is reachable
  # @see app/controllers/mailjet_controller#event
  describe 'async' do
    subject { AsyncService.new(described_class).handle_event(Hash.new.to_json) }

    context 'no response' do
      after { subject }

      it { expect(described_class).to receive(:handle_event) }
    end
  end
end
