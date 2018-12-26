module UserServices
  class DeleteUserService
    def initialize(user:)
      @user = user
    end

    def delete
      email = user.email
      user.update_columns(deleted: true,
                          phone: add_timestamp(:phone),
                          email: add_timestamp(:email))
      AsyncService.new(self.class).mailchimp_unsubscribe(email)
    end

    def self.mailchimp_unsubscribe email
      MailchimpService.strong_unsubscribe(
        list: :newsletter,
        email: email,
        reason: "compte supprimé dans l'app"
      )
    end

    private
    attr_reader :user

    def add_timestamp(key)
      "#{user.send(key)}-#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end
  end
end