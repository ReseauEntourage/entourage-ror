module TestingServices
  class Sms
    attr_accessor :user, :method_name

    def initialize user, method_name
      @user = user
      @method_name = method_name
    end

    def run
      raise "Bad method_name request" unless respond_to?(method_name)
      raise "User should be super_admin" unless user.super_admin?

      send(method_name)
    end

    def send_welcome
      UserServices::SMSSender.new(user: user).send_welcome_sms('xxxxxx')
    end

    def regenerate
      UserServices::SMSSender.new(user: user).regenerate_sms!
    end
  end
end
