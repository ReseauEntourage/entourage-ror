class MemberMailerPreview < ActionMailer::Preview
  def tour_report
    MemberMailer.tour_report(User.find(93).tours.last)
  end

  def welcome
    MemberMailer.welcome(User.last)
  end
end
