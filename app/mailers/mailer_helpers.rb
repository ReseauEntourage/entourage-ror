module MailerHelpers
  private

  def email_with_name(email, name)
    %("#{name}" <#{email}>)
  end
end
