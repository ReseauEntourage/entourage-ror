module SalesforceServices
  class Connect
    attr_accessor :interface, :instance

    @client = nil

    def initialize interface:, instance:
      @interface = interface
      @instance = instance
    end

    def self.client
      @client ||= SalesforceServices::Client.connexion
    end

    def client
      self.class.client
    end

    def updatable_fields
      raise NotImplementedError
    end

    def url
      return unless id = (instance&.salesforce_id || find_id)

      interface.record_url(id)
    end

    def is_synchable?
      true
    end

    def find_id
      return unless attributes = find_by_external_id
      return unless attributes.any?

      attributes['Id']
    end

    def find_by_external_id
      fetch_fields(['Id'])
    end

    def fetch
      fetch_fields(interface.sf_fields).except('attributes')
    end

    def fetch_fields fields
      value = instance.send(interface.external_id_key)
      value = "'#{value}'" unless value.is_a?(Float) || value.is_a?(Integer)

      client.query("select #{fields.join(', ')} from #{interface.table_name} where #{interface.external_id_value} = #{value}").first
    end

    def update
      return unless id = find_id

      client.update(interface.table_name, Id: id, **interface.mapped_fields)
    end

    def upsert
      upsert_from_fields(interface.mapped_fields)
    end

    def upsert_from_fields fields
      client.upsert!(
        interface.table_name,
        interface.external_id_value,
        "#{interface.external_id_value}": instance.send(interface.external_id_key),
        **fields
      )
    end

    def destroy
      return unless id = find_id

      client.update(interface.table_name, Id: id, Status: true)
    end
  end
end
