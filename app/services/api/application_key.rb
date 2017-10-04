module Api
  class ApplicationKey
    def initialize(api_key:)
      @api_key = api_key
    end

    def key_infos
      return api_keys["api_debug"] if Rails.env.test?

      api_keys[api_key]
    end

    private
    attr_reader :api_key

    #Generate keys with SecureRandom.hex(12)
    def api_keys
      {
        "api_debug" => {version: "1.0", device: "rspec", device_family: UserApplication::ANDROID},
        "b05e6d0d2be8" => {version: "1.0.3", device: "iOS", device_family: UserApplication::IOS},
        "32e2ced9df89" => {version: "1.0.24", device: "Android", device_family: UserApplication::ANDROID},
        "d05394bcf705bbd4d6923bd9" => {version: "1.1.0", device: "iOS", device_family: UserApplication::IOS},
        "7a8c1f9f4b973384aaff3ed3" => {version: "1.1.0", device: "Android", device_family: UserApplication::ANDROID},
        "fbe5b5e0bd4ec94146b3dc9b" => {version: "1.2.0", device: "iOS", device_family: UserApplication::IOS},
        "2b8259ac4aad2cfd0b46be77" => {version: "1.2.0", device: "Android", device_family: UserApplication::ANDROID},
        "91f908e8f674fc9dfc5c1dba" => {version: "1.9.0", device: "iOS", device_family: UserApplication::IOS},
        "f28b6ff3362be6dd408e4bae" => {version: "1.9.0", device: "Android", device_family: UserApplication::ANDROID},
        "aa8b4eaa3701cf943fde3624" => {version: "2.0.0", device: "iOS", device_family: UserApplication::IOS},
        "8a3ef2f6b712b96ac4d0d654" => {version: "2.0.0", device: "Android", device_family: UserApplication::ANDROID},
        "c39c3a55be091ea3a68cd96f" => {version: "2.1.0", device: "iOS", device_family: UserApplication::IOS},
        "53d287d3548f5cd28a2ae28a" => {version: "2.1.0", device: "Android", device_family: UserApplication::ANDROID},
        "416a76cfc2c79d050f17909b" => {version: "2.2.0", device: "iOS", device_family: UserApplication::IOS},
        "dd47b51df9a7f602e890b7a6" => {version: "2.2.0", device: "Android", device_family: UserApplication::ANDROID},
        "b6d9f316189b8fb207d64f12" => {version: "3.0.0", device: "iOS", device_family: UserApplication::IOS},
        "25a28b3aba65f8be85295946" => {version: "3.0.0", device: "Android", device_family: UserApplication::ANDROID},
        "e8999d7ce425154f68c4b552" => {version: "3.1.0", device: "iOS", device_family: UserApplication::IOS},
        "e467ee4b5918753fca9cc8af" => {version: "3.1.0", device: "Android", device_family: UserApplication::ANDROID},

        "0eb393e29d32a9595e4bf30d" => {version: "3.3.0", device: "iOS", device_family: UserApplication::IOS},
        "0fe1d87ed0be6530157ac07a" => {version: "3.3.0", device: "Android", device_family: UserApplication::ANDROID},

        "b56eb037366451dc1c6b1e8e" => {version: "3.4.0", device: "iOS", device_family: UserApplication::IOS},
        "b282b2616bb751fbd37cbf46" => {version: "3.4.0", device: "Android", device_family: UserApplication::ANDROID},

        "dfa6227b5e0dbe989ead945b" => {version: "3.5.0", device: "iOS", device_family: UserApplication::IOS},
        "d75e03bd7cce4ebe45b3e45b" => {version: "3.5.0", device: "Android", device_family: UserApplication::ANDROID},

        "f4f59f359c6a8c7dc53064da" => {version: "3.6.0", device: "iOS", device_family: UserApplication::IOS},
        "fbe5ec205f074b7533c2dbd6" => {version: "3.6.0", device: "Android", device_family: UserApplication::ANDROID},
      }
    end

    class Version
      include Comparable

      def initialize version
        @version_array = parse(version)
      end

      def <=> other
        @version_array <=> parse(other)
      end

      private
      def parse value
        raise ArgumentError, "version must be a String" unless value.is_a?(String)
        value.split('.')
      end
    end
  end
end