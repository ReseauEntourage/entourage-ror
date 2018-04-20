module Api
  class ApplicationKey
    def initialize(api_key:)
      @api_key = api_key
    end

    def key_infos
      if Rails.env.test? && api_key.nil?
        return api_keys.find { |_, infos| infos[:device] == 'rspec' && infos[:community] == $server_community }[1]
      end

      api_keys[api_key]
    end

    private
    attr_reader :api_key

    #Generate keys with SecureRandom.hex(12)
    def api_keys
      {
        "api_debug" => {version: "1.0", device: "rspec", device_family: UserApplication::ANDROID,                    community: 'entourage'},
        "api_debug_pfp" => {version: "1.0", device: "rspec", device_family: UserApplication::ANDROID,                community: 'pfp'},
        "api_debug_web" => {version: "1.0", device: "rspec", device_family: UserApplication::WEB,                    community: 'entourage'},
        "b05e6d0d2be8" => {version: "1.0.3", device: "iOS", device_family: UserApplication::IOS,                     community: 'entourage'},
        "32e2ced9df89" => {version: "1.0.24", device: "Android", device_family: UserApplication::ANDROID,            community: 'entourage'},
        "d05394bcf705bbd4d6923bd9" => {version: "1.1.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "7a8c1f9f4b973384aaff3ed3" => {version: "1.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "fbe5b5e0bd4ec94146b3dc9b" => {version: "1.2.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "2b8259ac4aad2cfd0b46be77" => {version: "1.2.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "91f908e8f674fc9dfc5c1dba" => {version: "1.9.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "f28b6ff3362be6dd408e4bae" => {version: "1.9.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "aa8b4eaa3701cf943fde3624" => {version: "2.0.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "8a3ef2f6b712b96ac4d0d654" => {version: "2.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "c39c3a55be091ea3a68cd96f" => {version: "2.1.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "53d287d3548f5cd28a2ae28a" => {version: "2.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "416a76cfc2c79d050f17909b" => {version: "2.2.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "dd47b51df9a7f602e890b7a6" => {version: "2.2.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "b6d9f316189b8fb207d64f12" => {version: "3.0.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "25a28b3aba65f8be85295946" => {version: "3.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "e8999d7ce425154f68c4b552" => {version: "3.1.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "e467ee4b5918753fca9cc8af" => {version: "3.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "0eb393e29d32a9595e4bf30d" => {version: "3.3.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "0fe1d87ed0be6530157ac07a" => {version: "3.3.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "b56eb037366451dc1c6b1e8e" => {version: "3.4.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "b282b2616bb751fbd37cbf46" => {version: "3.4.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "dfa6227b5e0dbe989ead945b" => {version: "3.5.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "d75e03bd7cce4ebe45b3e45b" => {version: "3.5.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "f4f59f359c6a8c7dc53064da" => {version: "3.6.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "fbe5ec205f074b7533c2dbd6" => {version: "3.6.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "c8ebfe97c93c4135f512f330" => {version: "4.0.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "cf52de007ca906bc2b25a6cf" => {version: "4.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "5d6954d62941383ee57c723f" => {version: "4.1.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "54dd058c4240096ef1cb51c2" => {version: "4.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "96058f62d45662b47bfcd101" => {version: "4.2.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "946478b0f527ef016f03c4b3" => {version: "4.2.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "4a305d01ceca5281e7bcc7e2" => {version: "4.3.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "4d684bad4f06e5366e5c9bdf" => {version: "4.3.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "188e1be088dc4f8690819116" => {version: "4.4.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "1307d4a101dc2e01855960b1" => {version: "4.4.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "7d02a340c88e851bc87097a3" => {version: "4.5.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "76dd2c0eb8558fd6ce24a924" => {version: "4.5.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "69b3961a0d1e6b99c4b36a40" => {version: "4.6.0", device: "iOS", device_family: UserApplication::IOS,         community: 'entourage'},
        "6fb0d70355e30b640378bf79" => {version: "4.6.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},

        "2c139df443e3ba92573962f1" => {version: "5.0.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'entourage'},
        "2319683867b6c10281896aa6" => {version: "5.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "26fb18404cb9d6afebc87349" => {version: "5.0.0", device: "web",     device_family: UserApplication::WEB,     community: 'entourage'},
        "2d5771c1d7273cb1817c4aaa" => {version: "5.0.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        "2ab4573f2d1c370f084ed7db" => {version: "5.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        "8482f2d498799ed526738c0d" => {version: "5.1.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'entourage'},
        "8f7583e72131416c4ebc1e38" => {version: "5.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'entourage'},
        "86786d91ac66766cc38f1490" => {version: "5.1.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        "81054ed8deb402cb0e1162c6" => {version: "5.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},
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
