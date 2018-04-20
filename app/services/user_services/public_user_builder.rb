module UserServices
  class PublicUserBuilder < UserBuilder
    def initialize(params:, community:)
      @community = community
      super(params: params)
    end

    def new_user(sms_code=nil)
      user = User.new(params)
      user.user_type = 'public'
      user.community = community.slug
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user
    end


    def update(user:, platform: nil)
      yield callback if block_given?

      return callback.on_failure.try(:call, user) if params.keys.include?("phone")

      if params.key?('sms_code') && platform != :mobile
        return callback.on_failure.try(:call, user)
      end

      avatar_file = params.delete(:avatar)
      if avatar_file
        UserServices::Avatar.new(user: user).upload(file: avatar_file)
      end

      should_send_email = params[:email] && user.email.nil?
      if user.update_attributes(params)
        MemberMailer.welcome(user).deliver_later if should_send_email
        callback.on_success.try(:call, user)
      else
        callback.on_failure.try(:call, user)
      end
    end

    private
    attr_reader :community

  end
end
