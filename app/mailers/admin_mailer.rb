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

  def user_report(reported_user:, reporting_user:, message:)
    @reported_user  = reported_user

    if reporting_user.is_a?(User)
      @reporting_user = reporting_user
    elsif AnonymousUserService.token?(reporting_user, community: $server_community)
      @reporting_user = AnonymousUserService.find_user_by_token(reporting_user, community: $server_community)
    else
      raise "unexpected value for `reporting_user`"
    end

    @message        = message
    mail to: "contact@entourage.social",
         subject: "Signalement d'un utilisateur - #{reported_user.first_name} #{reported_user.last_name} - #{reported_user.postal_codes.join(', ')}"
  end

  def group_report(reported_group:, reporting_user:, message:)
    @reported_group  = reported_group

    if reporting_user.is_a?(User)
      @reporting_user = reporting_user
    elsif AnonymousUserService.token?(reporting_user, community: $server_community)
      @reporting_user = AnonymousUserService.find_user_by_token(reporting_user, community: $server_community)
    else
      raise "unexpected value for `reporting_user`"
    end

    group_name = GroupService.name(@reported_group, :u)
    group_postal_code = GroupService.postal_code(@reported_group)

    @message        = message
    mail to: "contact@entourage.social",
         subject: %(Signalement d'#{group_name} : "#{reported_group.title}" - #{group_postal_code}")
  end

  def forgot_password(user:)
    @user = user
    @token = user.reset_admin_password_token

    mail to: user.email,
         subject: "Réinitialiser votre mot de passe - #{user.first_name} #{user.last_name}"
  end
end
