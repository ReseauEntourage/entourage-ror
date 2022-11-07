module UserServices
  class DeleteUserService
    def initialize(user:)
      @user = user
    end

    def delete
      email = user.email
      user['phone'] = add_timestamp(:phone) # we want after_update callback but do not want PhoneBuilder
      user.deleted = true
      user.email = add_timestamp(:email)
      user.save(validate: false)

      if user.community == :entourage
        AsyncService.new(self.class).mailchimp_unsubscribe(email)
      end
    end

    def self.mailchimp_unsubscribe email
      MailchimpService.strong_unsubscribe(
        list: :newsletter,
        email: email,
        reason: "compte supprimé dans l'app"
      )
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
