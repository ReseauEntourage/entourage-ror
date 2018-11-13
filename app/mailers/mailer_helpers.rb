module MailerHelpers
  private

  def email_with_name(email, name)
    %("#{name}" <#{email}>)
  end

  def community_prefix community, identifier
    prefix = community == :entourage ? nil : community.slug
    [prefix, identifier].compact.map(&:to_s).join('_')
  end
end
