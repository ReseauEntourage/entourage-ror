class AdminMailer < ActionMailer::Base
  default from: "contact@entourage.social"

  def received_message(message)
    @message = message
    mail(to: "contact@entourage.social", subject: "Un nouveau message a été envoyé à l'équipe entourage")
  end

  def registration_request(request_id)
    @request = RegistrationRequest.find(request_id)
    mail to: "associations@entourage.social",
         subject: "Nouvelle demandes d'adhésion : #{@request.organization_field('name')}"
  end

  def tour_request(id:, user_id:, message:)
    @tour_area = TourArea.find(id)
    @user = User.find(user_id)
    @message = message

    mail to: @tour_area.email,
         subject: "Nouvelle demande de maraude pour #{@tour_area.area} (#{@tour_area.departement})"
  end

  def forgot_password(user:)
    @user = user
    @token = user.reset_admin_password_token

    mail to: user.email,
         subject: "Réinitialiser votre mot de passe - #{user.first_name} #{user.last_name}"
  end
end
