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

    #Generate keys with
    def api_keys
      {
        "api_debug" => {version: "1.0", device: "foo"},
        "b05e6d0d2be8" => {version: "1.0.3", device: "iOS"},
        "32e2ced9df89" => {version: "1.0.24", device: "Android"}
      }
    end
  end
end