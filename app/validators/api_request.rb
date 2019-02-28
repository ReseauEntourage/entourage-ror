class ApiRequest
  def initialize(params:, headers:, env:)
    @params = params
    @headers = headers
    @env = env
  end

  def validate!
    return if Rails.env.test?

    raise Unauthorised unless key_infos.present?
  end

  def key_infos
    key_object.key_infos
  end

  def platform
    raise Unauthorised unless key_infos.present?
    key_object.platform
  end

  def api_key
    headers['X-API-KEY'] || env['X-API-KEY'] || env['HTTP_X_API_KEY'] || env['HTTP_API_KEY']
  end

  class Unauthorised < StandardError; end

  private
  attr_reader :params, :headers, :env

  def key_object
    @key_object ||= Api::ApplicationKey.new(api_key: api_key)
  end
end
