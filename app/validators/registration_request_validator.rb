class RegistrationRequestValidator
  def initialize(params:)
    @organization = Organization.new(params["organization"].except("logo_key"))
    @user = UserServices::UserBuilder.new(params:params["user"], organization:@organization).new_user
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