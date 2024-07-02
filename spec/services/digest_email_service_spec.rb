require 'rails_helper'

describe DigestEmailService, type: :service do
  describe '.next_delivery' do
    before { Timecop.freeze(Time.zone.local(2019, 3, 28, 18, 30)) }

    it "same day later" do
      expect(DigestEmailService.next_delivery day: :thursday,
                                       time: 19,
                                       min_interval: 2.weeks,
                                       previous_delivery: nil
      ).to eq(
        Time.zone.local(2019, 3, 28, 19, 0)
      )
    end

    it "same day earlier" do
      expect(DigestEmailService.next_delivery day: :thursday,
                                       time: 18,
                                       min_interval: 2.weeks,
                                       previous_delivery: nil
      ).to eq(
        Time.zone.local(2019, 4, 4, 18, 0)
      )
    end

    it "previous delivery farther than min interval" do
      expect(DigestEmailService.next_delivery day: :thursday,
                                       time: 19,
                                       min_interval: 2.weeks,
                                       previous_delivery: 2.weeks.ago
      ).to eq(
        Time.zone.local(2019, 3, 28, 19, 0)
      )
    end

    it "previous delivery closer than min interval" do
      expect(DigestEmailService.next_delivery day: :thursday,
                                       time: 19,
                                       min_interval: 2.weeks,
                                       previous_delivery: 13.days.ago
      ).to eq(
        Time.zone.local(2019, 4, 4, 19, 0)
      )
    end
  end

  # verify async method is reachable
  # @see app/services/digest_email_service#deliver_scheduled!
  describe 'async' do
    let(:digest_email) { create :digest_email, status: :scheduled }

    subject { AsyncService.new(described_class).deliver(digest_email) }

    context 'no response' do
      after { subject }

      it { expect(described_class).to receive(:deliver) }
    end
  end
end
