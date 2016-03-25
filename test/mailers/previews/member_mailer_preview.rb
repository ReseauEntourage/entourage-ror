class MemberMailerPreview < ActionMailer::Preview
  def registration_request_accepted
    MemberMailer.registration_request_accepted(User.find(93))
  end

  def tour_report
    MemberMailer.tour_report(User.find(93).tours.last)
  end
end