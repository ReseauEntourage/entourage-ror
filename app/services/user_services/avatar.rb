module UserService
  class Avatar
    def initialize(user:)
      @user = user
    end

    def full_size_url

    end

    def thumbnail_url

    end

    private
    attr_reader :user

    def key
      user.avatar_key
    end
  end
end