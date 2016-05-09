module UserServices
  class UserApplications
    def initialize(user:)
      @user = user
    end

    def android_app
      app(UserApplication::ANDROID)
    end

    def ios_app
      app(UserApplication::IOS)
    end

    private
    attr_reader :user

    def app(type)
      user.user_applications.where(device_family: type).order("updated_at DESC").first
    end
  end
end