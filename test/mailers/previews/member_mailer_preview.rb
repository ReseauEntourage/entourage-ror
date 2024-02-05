class MemberMailerPreview < ActionMailer::Preview
  def welcome
    MemberMailer.welcome(User.last)
  end
end
