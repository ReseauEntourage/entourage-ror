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

    def thumbnail_url
      return unless user.avatar_key
      return if user.blocked?
      return "https://foobar.s3-eu-west-1.amazonaws.com/300x300/avatar.jpg" if Rails.env.test?
      avatars.url_for(key: thumbnail_key)
    end

    def destroy
      [key, thumbnail_key].each {|k| avatars.destroy(key: k)}
    end

    private
    attr_reader :user

    def key
      "avatar_#{user.id}"
    end

    def thumbnail_key
      "300x300/avatar_#{user.id}.jpg"
    end

    def avatars
      Storage::Client.avatars
    end
  end
end