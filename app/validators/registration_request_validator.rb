class RegistrationRequestValidator
  def initialize(params:)
    @params = params
  end

  def valid?
    organization = Organization.new(params["organization"])
    user = User.new(params["user"])
    user.organization = organization

    organization.valid? &&
    user.valid?
  end

  private
  attr_reader :params
end