module NotificationTruncationService
  def self.truncate_message! notification
    excess_bytes = notification.payload_data_size - payload_data_byte_limit(notification)

    return unless excess_bytes > 0

    data = notification.data
    message = data['content']['message']

    message = truncate_to_byte_length(message, message.bytesize - excess_bytes)

    data['content']['message'] = message
    notification[:data] = nil
    notification.data = data

    notification
  end

  def self.truncate_to_byte_length string, byte_length
    return string.dup unless string.bytesize > byte_length

    omission = '...'
    byte_length -= omission.length
    byte_length = 0 if byte_length < 0
    string = string.mb_chars.compose.limit(byte_length).to_s
    "#{string}#{omission}"
  end

  def self.payload_data_byte_limit notification
    notification.class.validators.find { |v| Rpush::Client::ActiveModel::PayloadDataSizeValidator === v }.options[:limit]
  end
end
