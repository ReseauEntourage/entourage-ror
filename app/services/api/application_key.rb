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

    private
    attr_reader :api_key

    #Generate keys with SecureRandom.hex(12)
    def api_keys
      {
        'api_debug' => {version: '1.0', device: 'rspec', device_family: UserApplication::ANDROID,                    community: 'entourage'},
        'api_debug_pfp' => {version: '1.0', device: 'rspec', device_family: UserApplication::ANDROID,                community: 'pfp'},
        'api_debug_web' => {version: '1.0', device: 'rspec', device_family: UserApplication::WEB,                    community: 'entourage'},
        'b05e6d0d2be8' => {version: '1.0.3', device: 'iOS', device_family: UserApplication::IOS,                     community: 'entourage'},
        '32e2ced9df89' => {version: '1.0.24', device: 'Android', device_family: UserApplication::ANDROID,            community: 'entourage'},
        'd05394bcf705bbd4d6923bd9' => {version: '1.1.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '7a8c1f9f4b973384aaff3ed3' => {version: '1.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        'fbe5b5e0bd4ec94146b3dc9b' => {version: '1.2.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '2b8259ac4aad2cfd0b46be77' => {version: '1.2.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        '91f908e8f674fc9dfc5c1dba' => {version: '1.9.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'f28b6ff3362be6dd408e4bae' => {version: '1.9.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        'aa8b4eaa3701cf943fde3624' => {version: '2.0.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '8a3ef2f6b712b96ac4d0d654' => {version: '2.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        'c39c3a55be091ea3a68cd96f' => {version: '2.1.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '53d287d3548f5cd28a2ae28a' => {version: '2.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        '416a76cfc2c79d050f17909b' => {version: '2.2.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'dd47b51df9a7f602e890b7a6' => {version: '2.2.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        'b6d9f316189b8fb207d64f12' => {version: '3.0.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '25a28b3aba65f8be85295946' => {version: '3.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        'e8999d7ce425154f68c4b552' => {version: '3.1.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'e467ee4b5918753fca9cc8af' => {version: '3.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '0eb393e29d32a9595e4bf30d' => {version: '3.3.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '0fe1d87ed0be6530157ac07a' => {version: '3.3.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        'b56eb037366451dc1c6b1e8e' => {version: '3.4.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'b282b2616bb751fbd37cbf46' => {version: '3.4.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        'dfa6227b5e0dbe989ead945b' => {version: '3.5.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'd75e03bd7cce4ebe45b3e45b' => {version: '3.5.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        'f4f59f359c6a8c7dc53064da' => {version: '3.6.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'fbe5ec205f074b7533c2dbd6' => {version: '3.6.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        'c8ebfe97c93c4135f512f330' => {version: '4.0.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        'cf52de007ca906bc2b25a6cf' => {version: '4.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '5d6954d62941383ee57c723f' => {version: '4.1.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '54dd058c4240096ef1cb51c2' => {version: '4.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '96058f62d45662b47bfcd101' => {version: '4.2.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '946478b0f527ef016f03c4b3' => {version: '4.2.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '4a305d01ceca5281e7bcc7e2' => {version: '4.3.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '4d684bad4f06e5366e5c9bdf' => {version: '4.3.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '188e1be088dc4f8690819116' => {version: '4.4.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '1307d4a101dc2e01855960b1' => {version: '4.4.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '7d02a340c88e851bc87097a3' => {version: '4.5.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '76dd2c0eb8558fd6ce24a924' => {version: '4.5.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '69b3961a0d1e6b99c4b36a40' => {version: '4.6.0', device: 'iOS', device_family: UserApplication::IOS,         community: 'entourage'},
        '6fb0d70355e30b640378bf79' => {version: '4.6.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '2c139df443e3ba92573962f1' => {version: '5.0.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '2319683867b6c10281896aa6' => {version: '5.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        '26fb18404cb9d6afebc87349' => {version: '5.0.0', device: 'web',     device_family: UserApplication::WEB,     community: 'entourage'},
        #"2d5771c1d7273cb1817c4aaa" => {version: "5.0.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"2ab4573f2d1c370f084ed7db" => {version: "5.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '8482f2d498799ed526738c0d' => {version: '5.1.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '8f7583e72131416c4ebc1e38' => {version: '5.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"86786d91ac66766cc38f1490" => {version: "5.1.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"81054ed8deb402cb0e1162c6" => {version: "5.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'a88f0ed50d8d1e7cd3a2420d' => {version: '5.2.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'ae0269b4497666daf14bef28' => {version: '5.2.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"a5b68de05b21e31af6a3d094" => {version: "5.2.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"a194d15d56ddc1bb74bb4f0c" => {version: "5.2.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '36bcb4bb6a6a99011108d1cb' => {version: '5.3.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '3159ba69b035fb771ba797f4' => {version: '5.3.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"359aa27301eab00d2a3575de" => {version: "5.3.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"3e9cb00335d4329b2d802a5b" => {version: "5.3.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'b42ea0eb99c451139b5cda4a' => {version: '5.4.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'b8af267515fc5f33f4fa07c5' => {version: '5.4.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"b1c5269351e5405dafada829" => {version: "5.4.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"b582828ba2e4d0f157d73595" => {version: "5.4.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'fd4da3f7cbeed6cce026e276' => {version: '5.5.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'f30c711173105ee2dd7289eb' => {version: '5.5.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"f7d90b14c6e2dc641e4343e8" => {version: "5.5.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"f27ed4fda9a2cbf199046047" => {version: "5.5.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'b9a71efa52b897b4c4571317' => {version: '5.6.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'b6b94fc66f75b5006cb7214f' => {version: '5.6.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"b967b44f99b26c25ad03b84f" => {version: "5.6.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"b6fce1b1fcd97325791e80bd" => {version: "5.6.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '0755d181cdeaacecfd042676' => {version: '5.7.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '00e04e1ee35565b81fcff4fb' => {version: '5.7.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"01c4a4deacf9db7d25058dda" => {version: "5.7.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"024ffc16d69059521b7b0caa" => {version: "5.7.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '991ad6dcc3fa6804a58fe24b' => {version: '5.8.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '9de7f5860fd0b1067c1fd725' => {version: '5.8.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"9d52326aa7d9fe73aa1b3d0f" => {version: "5.8.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"9ebf2b47e35046e43dae5e31" => {version: "5.8.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'ef710742275081847aa848ea' => {version: '6.0.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'eba339ae2dac29941af8cbd6' => {version: '6.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"e94eceafb5beaddc4f384925" => {version: "6.0.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"ee15c4f26482e61b72f1f565" => {version: "6.0.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        'df90bc36321c874aa5a66795' => {version: '6.1.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        'd2e4767cb77fafdca80fd59b' => {version: '6.1.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"dee6d662ff91b0b4d1412d1f" => {version: "6.1.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"da45a612b1f1b085a86976e6" => {version: "6.1.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '13f7d4ed0009b761df1c9400' => {version: '6.2.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '145afedd05482e1e91ed2990' => {version: '6.2.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
        #"11aabfa5967deb0d7a2ea16e" => {version: "6.2.0", device: "iOS",     device_family: UserApplication::IOS,     community: 'pfp'},
        #"14fe3580873758c2a63f14aa" => {version: "6.2.0", device: "Android", device_family: UserApplication::ANDROID, community: 'pfp'},

        '5071ce2e119e8a43747cd89c' => {version: '8.0.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '50968038037d1df181e8372d' => {version: '8.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},

        '44b2f3f3e7fd9b9c391a2f06' => {version: '9.0.0', device: 'iOS',     device_family: UserApplication::IOS,     community: 'entourage'},
        '4a7373f3e7dd45fc391a2f19' => {version: '9.0.0', device: 'Android', device_family: UserApplication::ANDROID, community: 'entourage'},
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
        raise ArgumentError, 'version must be a String' unless value.is_a?(String)
        value.split('.')
      end
    end
  end
end
