module Facebook
  class FacebookUserBuilder
    def initialize(facebook_user:)
      @facebook_user = facebook_user
    end

    def update_user(user)
      user.tap do |user|
        user.email ||= facebook_user["email"] unless facebook_user["email"].nil?
        user.first_name ||= facebook_user["first_name"]
        user.last_name ||= facebook_user["last_name"]
      end
    end

    private
    attr_reader :facebook_user
  end
end