module UserServices
  class DeleteUserService
    def initialize(user:)
      @user = user
    end

    def delete
      user.update_columns(deleted: true,
                          phone: add_timestamp(:phone),
                          email: add_timestamp(:email))
      # use `update` to trigger post-update MailChimp sync
      user.update(accepts_emails: false)
    end

    private
    attr_reader :user

    def add_timestamp(key)
      "#{user.send(key)}-#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end
  end
end