module Api
  class ApplicationKey
    def initialize(api_key:)
      @api_key = api_key
    end

    def key_infos
      if Rails.env.test? && api_key.nil?
        return api_keys['api_debug']
      end

      api_keys[api_key]
    end

    def platform
      @platform ||= begin
        case key_infos.try(:[], :device_family)
        when UserApplication::ANDROID, UserApplication::IOS
          :mobile
        when UserApplication::WEB
          :web
        else
          nil
        end
      end
    end

    class Version
      include Comparable

      def initialize version
        @version_array = parse(version)
      end

      def <=> other
        @version_array <=> (other.is_a?(Version) ? other.to_a : parse(other))
      end

      def to_a
        @version_array.dup
      end

      private
      def parse value
        raise ArgumentError, 'version must be a String' unless value.is_a?(String)
        value.split('.').map(&:to_i)
      end
    end

    private
    attr_reader :api_key

    # iOS/Android API keys are not stored in this file: they live in the API_KEYS_IOS /
    # API_KEYS_ANDROID env vars, each a comma-separated list of "version:key" pairs, e.g.
    # "9.0.0:44b2f3f3e7fd9b9c391a2f06,10.0.0:a5cc26940b6f91fa8e462a3f".
    # Generate a new key with SecureRandom.hex(12) and append it, don't reorder/remove existing ones.
    # From HMAC_SINCE onward, a platform's key carries that platform's shared HMAC_SECRET_*.
    HMAC_SINCE = '9.0.0'

    def self.parse_platform_keys(env_var, device:, device_family:, hmac_secret:)
      ENV[env_var].to_s.split(',').each_with_object({}) do |entry, keys|
        version, key = entry.split(':', 2)
        info = {version: version, device: device, device_family: device_family}
        info[:hmac_secret] = hmac_secret if Version.new(version) >= HMAC_SINCE
        keys[key] = info
      end
    end
    private_class_method :parse_platform_keys

    IOS_KEYS = parse_platform_keys('API_KEYS_IOS', device: 'iOS', device_family: UserApplication::IOS, hmac_secret: ENV['HMAC_SECRET_IOS'])
    ANDROID_KEYS = parse_platform_keys('API_KEYS_ANDROID', device: 'Android', device_family: UserApplication::ANDROID, hmac_secret: ENV['HMAC_SECRET_ANDROID'])

    def api_keys
      {
        'api_debug' => {version: '1.0', device: 'rspec', device_family: UserApplication::ANDROID, hmac_secret: 'rspec_hmac_secret'},
        'api_debug_web' => {version: '1.0', device: 'rspec', device_family: UserApplication::WEB, hmac_secret: 'rspec_hmac_secret'},
        '26fb18404cb9d6afebc87349' => {version: '5.0.0', device: 'web', device_family: UserApplication::WEB},
      }.merge(IOS_KEYS).merge(ANDROID_KEYS)
    end
  end
end
