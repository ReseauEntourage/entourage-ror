require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:, organization:)
      @params = params
      @organization = organization
    end

    def token
      SecureRandom.hex(16)
    end

    def sms_code
      '%06i' % rand(1000000)
    end

    def create
      user = User.new(params)
      user.organization = organization
      user.token = token
      user.sms_code = sms_code
      user.save
    end

    private
    attr_reader :params, :organization
  end
end