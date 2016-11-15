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
      }
    end
  end
end