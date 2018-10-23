module UserServices
  class SmsCode
    def code
      '%06i' % SecureRandom.random_number(1000000)
    end

    def regenerate_sms!(user:, clear_password: false)
      new_sms_code = code
      user.sms_code = new_sms_code
      user.encrypted_password = nil if clear_password
      user.save!
      new_sms_code
    end
  end
end
