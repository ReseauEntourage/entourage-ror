module SalesforceServices
  class Connect
    attr_accessor :interface, :instance

    @client = nil

    def initialize interface:, instance:
      @interface = interface
      @instance = instance
    end

    def self.client
      @client ||= Restforce.new(
        username: ENV['SALESFORCE_USERNAME'],
        password: ENV['SALESFORCE_PASSWORD'],
        instance_url: ENV['SALESFORCE_LOGIN_URL'],
        host: ENV['SALESFORCE_HOST'],
        client_id: ENV['SALESFORCE_CLIENT_ID'],
        client_secret: ENV['SALESFORCE_CLIENT_SECRET'],
        api_version: '55.0',
        logger: Rails.logger,
        log_level: :debug
      )
    rescue Restforce::AuthenticationError => e
      Rails.logger.error "Erreur de connexion à Salesforce : #{e.message}"
      @client = nil # forces new connection on next try

      retry
    end

    def client
      self.class.client
    end

    def updatable_fields
      raise NotImplementedError
    end

    def is_synchable?
      true
    end

    def find_id
      return unless attributes = find_by_external_id
      return unless attributes.any?

      attributes["Id"]
    end

    def find_by_external_id
      fetch_fields(["Id"])
    end

    def fetch
      fetch_fields(interface.sf_fields)
    end

    def fetch_fields fields
      client.query("select #{fields.join(', ')} from #{interface.table_name} where #{interface.external_id_value} = #{instance.send(interface.external_id_key)}").first
    end

    def update
      update_from_id(find_id)
    end

    def update_from_id id
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
      client.update(interface.table_name, Id: find_id, Status: true)
    end
  end
end
