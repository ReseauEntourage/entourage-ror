module UserServices
  class UserApplications
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def app_tokens
      user.user_applications
        .select(:push_token, :device_family)
        .where(device_family: [UserApplication::ANDROID, UserApplication::IOS])
        .order("updated_at DESC")
        .first(3)
    end
  end
end
