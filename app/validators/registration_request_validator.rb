class RegistrationRequestValidator
  def initialize(params:)
    @organization = Organization.new(params["organization"].except("logo_key"))
    @user = UserServices::ProUserBuilder.new(params:params["user"], organization:@organization).new_or_upgraded_user
  end

  def valid?
    [organization.valid?, user.valid?].all?
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