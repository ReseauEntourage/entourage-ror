class SchemaValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    errors = ::JSON::Validator.fully_validate(schema(record), value, validate_schema: !Rails.env.production?)

    return if errors.empty?

    errors.each do |error|
      stripped_error = error.gsub(/ in schema \S{36}$/, '')
      record.errors.add(attribute, stripped_error)
    end
  end

  private

  def schema record
    schema = options[:with]

    case schema
    when Symbol
      record.send(schema)
    else
      schema
    end
  end
end
