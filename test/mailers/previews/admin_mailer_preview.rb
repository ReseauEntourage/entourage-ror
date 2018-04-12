class AdminMailerPreview < ActionMailer::Preview
  def user_report
    reported_user, reporting_user = User.last(2)
    message = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    AdminMailer.user_report(
      reported_user:  reported_user,
      reporting_user: reporting_user,
      message:        message
    )
  end
end
