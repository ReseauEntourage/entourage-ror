class MemberMailer < ActionMailer::Base
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

  def tour_report(tour)
    @tour = tour
    @user = tour.user
    
    mail(to: @user.email, subject: 'Résumé de la maraude')
  end
end
