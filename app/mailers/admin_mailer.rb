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
         subject: "Signalement d'un utilisateur - #{reported_user.first_name} #{reported_user.last_name}"
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

    @message        = message
    mail to: "contact@entourage.social",
         subject: %(Signalement d'#{group_name} : "#{reported_group.title}")
  end
end
