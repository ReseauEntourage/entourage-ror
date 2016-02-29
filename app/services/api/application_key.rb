module Api
  class ApplicationKey
    def initialize(api_key:)
      @api_key = api_key
    end

    def authorised?
      api_keys.keys.include?(api_key)
    end

    private
    attr_reader :api_key

    #Generate keys with SecureRandom.hex(12)
    def api_keys
      {
        "api_debug" => {version: "1.0", device: "foo"},
        "b05e6d0d2be8" => {version: "1.0.3", device: "iOS"},
        "32e2ced9df89" => {version: "1.0.24", device: "Android"},
        "d05394bcf705bbd4d6923bd9" => {version: "1.1.0", device: "iOS"},
        "7a8c1f9f4b973384aaff3ed3" => {version: "1.1.0", device: "Android"},
        "aa8b4eaa3701cf943fde3624" => {version: "2.0.0", device: "iOS"},
        "8a3ef2f6b712b96ac4d0d654" => {version: "2.0.0", device: "Android"}
      }
    end
  end
end