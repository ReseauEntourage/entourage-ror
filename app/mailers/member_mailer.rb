class MemberMailer < ActionMailer::Base
  default from: "contact@entourage.social"

  def tour_report(tour)
    @tour = tour
    @encounters = @tour.encounters
    @user = User.first
    @map_url = "https://maps.googleapis.com/maps/api/staticmap?size=512x512&path=color:0x0000ff|weight:5#{tour.get_coordinates_uri_static_map}"
    mail(to: @user.email, subject: 'R&eacute;sum&eacute; de la maraude')
  end
end



