module UserServices
  class Avatar
    def initialize(user:)
      @user = user
    end

    def upload(file:)
      extra = {content_type: file.content_type}
      avatars.upload(file: file, key: key, extra: extra)
      user.update(avatar_key: key)
    end

    def thumbnail_url expire: 1.day
      return unless user.avatar_key
      return if user.blocked?
      return "https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg" if Rails.env.test?
      avatars.url_for(key: thumbnail_key, extra: {expire: expire})
    end

    def destroy
      avatars.destroy(key: thumbnail_key)
    end

    private
    attr_reader :user

    def key
      user.avatar_key || SecureRandom.uuid
    end

    def thumbnail_key
      "300x300/#{user.avatar_key}"
    end

    def avatars
      Storage::Client.avatars
    end
  end
end
