class ApiRequestValidator
  def initialize(params:, headers:, env:)
    @params = params
    @headers = headers
    @env = env
  end

  def validate!
    return if Rails.env.test?

    raise UnauthorisedApiKeyError unless Api::ApplicationKey.new(api_key: api_key).authorised?
  end

  private
  attr_reader :params, :headers, :env

  def api_key
    headers['X-API-Key'] || env['X-API-Key']
  end
end

class UnauthorisedApiKeyError < StandardError; end