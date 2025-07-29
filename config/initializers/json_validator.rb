# Accepts ISO 8601, then converts it to RFC 3339 (JSON Schema standard)
#
# derived from
# https://github.com/ruby-json-schema/json-schema/blob/v2.6.2/lib/json-schema/attributes/formats/date_time_v4.rb

JSON::Validator.register_format_validator('date-time-iso8601', -> (data) {
  begin
    return unless data.is_a?(String)
    data.replace DateTime.iso8601(data).rfc3339(3)
  rescue TypeError, ArgumentError
    raise JSON::Schema::CustomFormatError, 'must be a valid ISO 8601 date/time string'
  end
})
