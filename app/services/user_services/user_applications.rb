module UserServices
  class UserApplications
    def initialize(user:)
      @user = user
    end

    def android_app_tokens
      app_tokens(UserApplication::ANDROID)
    end

    def ios_app_tokens
      app_tokens(UserApplication::IOS)
    end

    private
    attr_reader :user

    def app_tokens(type)
      user.user_applications.select(:push_token).where(device_family: type).order("updated_at DESC").first(3)
    end
  end
end
