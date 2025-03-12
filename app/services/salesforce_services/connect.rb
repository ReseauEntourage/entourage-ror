module SalesforceServices
  class Connect
    def initialize table_name
      @table_name = table_name
    end

    def client
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
    end

    def is_synchable?
      true
    end

    # describe table fields
    def table_fields
      return Hash.new unless metadata = client.describe(@table_name)

      metadata[:fields]
    end

    # describe table field values
    def table_field_values field
      table_fields(@table_name).find { |f| f[:name] == field }[:picklistValues]
    end

    # check whether a field includes a value
    # example: table_field_has_value?("Campaign", "Type_evenement__c", SalesforceServices::Outing::TYPE_EVENEMENT)
    def table_field_has_value? field, value
      table_field_values(@table_name, field).any? do |config|
        config["value"] == value
      end
    end

    # check whether table has fields with history tracking (flows)
    def table_tracked_fields_with_types
      client.query(%(
        SELECT DeveloperName, DataType FROM FieldDefinition
        WHERE EntityDefinition.QualifiedApiName = '#{@table_name}'
        AND IsFieldHistoryTracked = true
      )).map { |field| { name: field.DeveloperName, type: field.DataType }}
    end

    def table_has_cdc?
      client.get("/services/data/v57.0/sobjects/#{@table_name}ChangeEvent/describe")

      true
    rescue Restforce::NotFoundError
      false
    end
  end
end
