module SalesforceServices
  class Connect
    def initialize
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

    # describe object fields
    def object_fields object_name
      return Hash.new unless metadata = client.describe(object_name)

      metadata[:fields]
    end

    # describe object field values
    def object_field_values object_name, field
      object_fields(object_name).find { |f| f[:name] == field }[:picklistValues]
    end

    # check whether a field includes a value
    # example: object_field_has_value?("Campaign", "Type_evenement__c", SalesforceServices::Outing::TYPE_EVENEMENT)
    def object_field_has_value? object_name, field, value
      object_field_values(object_name, field).any? do |config|
        config["value"] == value
      end
    end
  end
end
