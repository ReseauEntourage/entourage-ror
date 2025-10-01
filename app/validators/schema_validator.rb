class SchemaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    schema_urn_suffix =
      case options[:with]
      when nil
        attribute.to_s
      when String
        options[:with]
      when Proc
        options[:with].call(record)
      else
        raise ArgumentError, 'SchemaValidator schema must be `true`, a String, or a Proc'
      end

    unless schema_urn_suffix.is_a? String
      raise ArgumentError, "SchemaValidator schema URN suffix #{schema_urn_suffix.inspect} is not a String"
    end

    schema = record.class.json_schema schema_urn_suffix
    schema_uri = "urn:#{record.class.name.underscore}:#{schema_urn_suffix}"
    value['$id'] = schema_uri

    errors = ::JSON::Validator.fully_validate(schema, value, validate_schema: !Rails.env.production?)

    return if errors.empty?

    errors.each do |error|
      stripped_error = error.gsub(/^The property '#\/' /, '')
                            .gsub(/^The property '#\/([^']+)'/, "'\\1'")
                            .gsub(/ in schema \S{36}$/, '')
      record.errors.add(attribute, stripped_error)
    end
  end
end
