require 'rails_helper'

RSpec.describe Phone::PhoneBuilder do
  describe '#looks_like_phone_number?' do
    subject { described_class.new(phone: phone).looks_like_phone_number? }

    where(:phone, :expected) do
      [
        ['+33 6 12 34 56 78', true],
        ['06 12 34 56 78',    true],
        ['+33 (0) 6 00 00 00 01 ',    true],
        ['1234',              false],
        ['foo@bar.fr',        false]
      ]
    end

    with_them do
      it { is_expected.to(eq(expected)) }
    end
  end

  describe '#unformat' do
    subject { described_class.new(phone: phone).unformat }

    context 'with a french number' do
      let(:phone) { '+33612345678' }

      it { is_expected.to(eq('0612345678')) }
    end

    context 'with a french number already formatted' do
      let(:phone) { '0612345678' }

      it { is_expected.to(eq('0612345678')) }
    end

    context 'with a foreign number' do
      let(:phone) { '+15551234567' }

      it { is_expected.to(eq('+15551234567')) }
    end

    context 'with nil' do
      let(:phone) { nil }

      it { is_expected.to(be_nil) }
    end
  end
end
