require 'rails_helper'

describe NotificationTruncationService, type: :service do
  let(:service) { NotificationTruncationService }

  describe '.truncate_message!' do
    it do
      # specially crafted string where the 4096 char truncation cuts in the middle of
      # a multi-byte character 'é'
      content = '-' * 4049 + 'xéabc'

      notification = Rpush::Fcm::Notification.new
      notification.data = {content: {message: content, extra: 'extra'}}
      expect(notification.payload_data_size).to eq 4097
      service.truncate_message! notification
      expect(notification.payload_data_size).to eq 4095
      expect(notification.data['content']['message']).to end_with 'x...'
    end
  end

  describe '.truncate_to_byte_length' do
    it 'behaves like String.truncate for single-byte characters' do
      string = 'abcde'

      special_values = [
        string.length,
        '...'.length,
        0
      ]

      test_values = special_values.flat_map do |special_value|
        [
          special_value - 1,
          special_value,
          special_value + 1
        ]
      end

      test_values.uniq.sort.each do |length|
        expect(service.truncate_to_byte_length(string, length))
          .to eq string.truncate(length)
      end
    end

    it 'truncates multi-bytes characters cleanly' do
      expect(service.truncate_to_byte_length("C'est l'été !", 12)).to eq "C'est l'..."
    end
  end

  describe '.payload_data_byte_limit' do
    subject { service.payload_data_byte_limit(notification) }

    context 'FCM' do
      let(:notification) { Rpush::Fcm::Notification.new }
      it { is_expected.to eq 4096 }
    end
  end
end
