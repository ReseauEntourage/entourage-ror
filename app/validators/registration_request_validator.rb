class RegistrationRequestValidator
  def initialize(params:)
    @organization = Organization.new(params["organization"])
    @user = User.new(params["user"])
    @user.organization = @organization

  end

  def valid?
    organization.valid? &&
    user.valid?
  end

  def organization_errors
    organization.errors.full_messages
  end

  def user_errors
    user.errors.full_messages
  end

  private
  attr_reader :user, :organization
end