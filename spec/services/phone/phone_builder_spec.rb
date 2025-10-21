require 'rails_helper'

RSpec.describe Phone::PhoneBuilder do
  describe '#looks_like_phone_number?' do
    subject { described_class.new(phone: phone).looks_like_phone_number? }

    where(:phone, :expected) do
      [
        ['+33 6 12 34 56 78', true],
        ['06 12 34 56 78',    true],
        ['1234',              false],
        ['foo@bar.fr',        false]
      ]
    end

    with_them do
      it { is_expected.to eq(expected) }
    end
  end
end
