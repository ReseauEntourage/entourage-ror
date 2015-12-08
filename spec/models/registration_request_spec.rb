require 'rails_helper'

RSpec.describe RegistrationRequest, type: :model do
  it { should validate_presence_of :status }
  it { should validate_presence_of :extra }
end