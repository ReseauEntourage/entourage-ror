class AdminMailer < ActionMailer::Base
  default from: "contact@entourage.social"

  def received_message(message)
    @message = message
    mail(to: "contact@entourage.social", subject: "Un nouveau message a été envoyé à l'équipe entourage")
  end

  def forgot_password(user:)
    @user = user
    @token = user.reset_admin_password_token

    mail to: user.email,
         subject: "Réinitialiser votre mot de passe - #{user.first_name} #{user.last_name}"
  end
end
