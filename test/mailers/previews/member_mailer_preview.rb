class MemberMailerPreview < ActionMailer::Preview
  def registration_request_accepted
    MemberMailer.registration_request_accepted(User.find(93))
  end
end