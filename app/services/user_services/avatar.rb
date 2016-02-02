module UserServices
  class Avatar
    def initialize(user:)
      @user = user
    end

    def upload(file:)
      extra = {content_type: file.content_type}
      Storage::Client.avatars.upload(file: file, key: key, extra: extra)
      user.update(avatar_key: key)
    end

    def full_size_url
      Storage::Client.avatars.url_for(key: key)
    end

    def thumbnail_url

    end

    private
    attr_reader :user

    def key
      "avatar_#{user.id}"
    end
  end
end