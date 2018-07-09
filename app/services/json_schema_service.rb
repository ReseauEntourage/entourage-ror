module JsonSchemaService
  def self.base
    schema = {
      type: :object,
      additionalProperties: false
    }

    schema[:properties] = yield || {}
    schema[:properties]['$id'] = { type: :string, format: :uri }
    schema[:required] ||= schema[:properties].keys if schema[:properties].any?

    schema
  end
end
