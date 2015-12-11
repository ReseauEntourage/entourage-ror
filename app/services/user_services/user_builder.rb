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

    def new_user
      user = User.new(params)
      user.organization = organization
      user.token = token
      user.sms_code = sms_code
      user
    end

    def create
      new_user.save
      UserServices::SMSSender.new(user: new_user).send_welcome_sms!
    end

    private
    attr_reader :params, :organization
  end
end