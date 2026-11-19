module UserServices
  class DeleteUserService
    def initialize(user:)
      @user = user
    end

    def delete
      email = user.email
      user['phone'] = add_timestamp(:phone) # we want after_update callback but do not want PhoneBuilder
      # a blocked user stays "blocked" once deleted, so that blocked accounts remain easy to find
      # and so that their phone number can still be refused at signup (see User.blocked_with_phone)
      user.validation_status = 'deleted' unless user.blocked?
      user.deleted = true
      user.email = add_timestamp(:email)
      user.save(validate: false)
    end

    def undelete
      user.update_columns(deleted: false,
                          phone: remove_timestamp(:phone),
                          email: remove_timestamp(:email))
    end

    private
    attr_reader :user

    def remove_timestamp(key)
      user.send(key)&.gsub(/-\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.*/, '').presence
    end

    def add_timestamp(key)
      value = remove_timestamp(key)
      return nil if value.blank?
      "#{value}-#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end
  end
end
