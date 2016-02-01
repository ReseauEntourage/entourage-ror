module UserServices
  class PublicUserBuilder < UserBuilder

    def new_user(sms_code=nil)
      user = User.new(params)
      user.user_type = 'public'
      user.token = token
      user.sms_code = sms_code || UserServices::SmsCode.new.code
      user
    end

  end
end