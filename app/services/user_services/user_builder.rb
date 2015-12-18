require "securerandom"

module UserServices
  class UserBuilder
    def initialize(params:, organization: nil)
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

    def create(send_sms: false)
      valid = new_user.save
      return new_user if !valid

      UserServices::SMSSender.new(user: new_user).send_welcome_sms! if send_sms
      new_user
    end

    def update(user:)
      snap_to_road = (params.delete(:snap_to_road) == "true")
      PreferenceServices::UserDefault.new(user: user).snap_to_road = snap_to_road
      user.update_attributes(params)
    end

    private
    attr_reader :params, :organization
  end
end