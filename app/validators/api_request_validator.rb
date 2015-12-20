class ApiRequestValidator
  def initialize(params:, headers:)
    @params = params
    @headers = headers
  end

  def validate!
    return if Rails.env.test?

    raise UnauthorisedApiKeyError unless Api::ApplicationKey.new(api_key: api_key).authorised?
  end

  private
  attr_reader :params, :headers

  def api_key
    headers['X-API-Key']
  end
end

class UnauthorisedApiKeyError < StandardError; end