module UserServices
  class SmsCode
    def code
      '%06i' % rand(1000000)
    end

    def regenerate_sms!(user:)
      new_sms_code = code
      user.sms_code = new_sms_code
      user.save
      new_sms_code
    end
  end
end