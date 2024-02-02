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
  end
end
